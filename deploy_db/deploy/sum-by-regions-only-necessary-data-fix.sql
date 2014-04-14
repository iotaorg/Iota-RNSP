-- Deploy sum-by-regions-only-necessary-data-fix
-- requires: sum-by-regions-only-necessary-data

BEGIN;


CREATE OR REPLACE FUNCTION compute_upper_regions(_ids integer[], _var_ids integer[], _variation_var_ids integer[], dates date[])
  RETURNS integer[] AS
$BODY$
DECLARE v_ret int[];
BEGIN

    -- faz a soma das variaveis comuns
    CREATE TEMP TABLE sum_data AS
    SELECT  r.upper_region,
                iv.valid_from,
                iv.user_id,
                iv.variable_id,

                case when v.summarization_method = 'sum' then sum(iv.value::numeric) else avg(iv.value::numeric) end as total,

                ARRAY(SELECT DISTINCT UNNEST(array_agg(iv.source)) ORDER BY 1) AS sources,

                count(DISTINCT r.id) AS qtde_regions,

                (SELECT count(1) FROM region xx WHERE xx.upper_region = r.upper_region ) AS total_regions

        FROM region r
        JOIN region_variable_value iv ON iv.region_id = r.id
        JOIN VARIABLE v ON iv.variable_id = v.id
        WHERE r.upper_region IN
                ( SELECT upper_region
                FROM region x
                WHERE x.id IN
                        (SELECT unnest($1))
                    AND x.depth_level= 3 )
            AND v.id IN
                ( SELECT unnest($2) )
            AND ( CASE WHEN $4 IS NULL THEN TRUE ELSE iv.valid_from IN
                        (SELECT unnest($4)) END )
            AND active_value = TRUE
            AND r.depth_level = 3
            AND v.type IN ('int', 'num')
        GROUP BY 1,
                2,
                3,
                4, v.summarization_method;

    CREATE TEMP TABLE _x AS
    SELECT
        sum_data.*
    FROM sum_data
    JOIN "user" u ON sum_data.user_id = u.id
    JOIN institute it ON it.id = u.institute_id
    WHERE CASE WHEN it.aggregate_only_if_full THEN qtde_regions = total_regions ELSE TRUE END;

    -- apaga as existentes
    DELETE
    FROM region_variable_value
    WHERE (region_id,
            user_id,
            valid_from,
            variable_id) IN
        ( SELECT upper_region,
                        user_id,
                        valid_from,
                        variable_id
        FROM sum_data )
    AND generated_by_compute = TRUE;

    drop table sum_data;

    -- insere como generated_by_compute=true
    INSERT INTO region_variable_value ( region_id, variable_id, valid_from,
                user_id, value_of_date, value, SOURCE, generated_by_compute )
    SELECT x.upper_region,
                x.variable_id,
                x.valid_from,
                x.user_id,
                x.valid_from,
                x.total::varchar,
                x.sources[1],
                TRUE
    FROM _x x;

    -- carrega as regioes superiores no retorno
    SELECT ARRAY
        (SELECT upper_region
        FROM _x
        GROUP BY 1) INTO v_ret;
    DROP TABLE _x;

    -- agora vamos fazer a soma das variaveis de variacoes
    CREATE TEMP TABLE sum_data AS
     SELECT r.upper_region,
                iv.valid_from,
                iv.user_id,
                iv.indicator_variation_id,
                iv.indicator_variables_variation_id,

                case when v.summarization_method = 'sum' then sum(iv.value::numeric) else avg(iv.value::numeric) end as total,

                count(DISTINCT r.id) AS qtde_regions,

                (SELECT count(1) FROM region xx WHERE xx.upper_region = r.upper_region ) AS total_regions

        FROM region r
        JOIN indicator_variables_variations_value iv ON iv.region_id = r.id
        JOIN indicator_variables_variations v ON iv.indicator_variables_variation_id = v.id WHERE r.upper_region IN
            ( SELECT upper_region
            FROM region x
            WHERE x.id IN
                    (SELECT unnest($1))
                AND x.depth_level= 3 )
        AND v.id IN
            ( SELECT unnest($3) )
        AND ( CASE WHEN $4 IS NULL THEN TRUE ELSE iv.valid_from IN
                    (SELECT unnest($4)) END )
        AND active_value = TRUE
        AND r.depth_level= 3
        AND v.type IN ('int', 'num')

        GROUP BY 1,
                2,
                3,
                4,
                5, v.summarization_method;

    CREATE TEMP TABLE _x AS
    SELECT
        sum_data.*
    FROM sum_data
    JOIN "user" u ON sum_data.user_id = u.id
    JOIN institute it ON it.id = u.institute_id
    WHERE CASE WHEN it.aggregate_only_if_full THEN qtde_regions = total_regions ELSE TRUE END;

    -- apagando valores existentes...
    DELETE
    FROM indicator_variables_variations_value
    WHERE (region_id,
            user_id,
            valid_from,
            indicator_variation_id,
            indicator_variables_variation_id) IN
        ( SELECT upper_region,
                        user_id,
                        valid_from,
                        indicator_variation_id,
                        indicator_variables_variation_id
        FROM sum_data )
    AND generated_by_compute = TRUE;


    -- inserindo novamente.
    INSERT INTO indicator_variables_variations_value ( region_id, indicator_variation_id,
            indicator_variables_variation_id, valid_from, user_id, value_of_date, value, generated_by_compute )
    SELECT x.upper_region,
                x.indicator_variation_id,
                x.indicator_variables_variation_id,
                x.valid_from,
                x.user_id,
                x.valid_from,
                x.total::varchar,
                TRUE
    FROM _x x;

    -- removendo temp table, por causa dos testes que rodam na mesma transection.
    DROP TABLE _x;
    DROP TABLE sum_data;

    -- ok
    RETURN v_ret;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

DROP FUNCTION compute_upper_regions(integer[]);

select compute_upper_regions(
    ARRAY(select id from region where depth_level = 3 )::int[],
    ARRAY(select variable_id from indicator_variable )::int[],
    ARRAY(select id from indicator_variables_variations )::int[],
    null
);

COMMIT;
