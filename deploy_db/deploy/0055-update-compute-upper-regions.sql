-- Deploy 0055-update-compute-upper-regions
-- requires: variable_summarization

BEGIN;

DROP FUNCTION compute_upper_regions(integer[], integer[], integer[], date[]);

-- drop FUNCTION compute_upper_regions(_ids integer[], _var_ids integer[], _var_variation_ids integer[], _dates date[], _cur_level int);
CREATE OR REPLACE FUNCTION compute_upper_regions(_ids integer[], _var_ids integer[], _var_variation_ids integer[], _dates date[], _cur_level int)
  RETURNS boolean AS
$BODY$
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
                (
                    SELECT upper_region
                    FROM region x
                    WHERE x.id IN
                        (SELECT unnest(_ids))
                    AND x.depth_level = _cur_level
                )
            AND ( CASE WHEN _var_ids IS NULL THEN TRUE ELSE v.id IN
                        (SELECT unnest(_var_ids)) END )

            AND ( CASE WHEN _dates IS NULL THEN TRUE ELSE iv.valid_from IN
                        (SELECT unnest(_dates)) END )
            AND active_value = TRUE
            AND r.depth_level = _cur_level
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
                user_id, value_of_date, value, SOURCE, generated_by_compute, active_value )
    SELECT x.upper_region,
                x.variable_id,
                x.valid_from,
                x.user_id,
                x.valid_from,
                x.total::varchar,
                x.sources[1],
                TRUE,
                TRUE
    FROM _x x;

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
            (
                SELECT upper_region
                FROM region x
                WHERE x.id IN
                        (SELECT unnest(_ids))
                AND x.depth_level= _cur_level
            )

        AND ( CASE WHEN _var_variation_ids IS NULL THEN TRUE ELSE v.id IN
                    (SELECT unnest(_var_variation_ids)) END )

        AND ( CASE WHEN _dates IS NULL THEN TRUE ELSE iv.valid_from IN
                    (SELECT unnest(_dates)) END )

        AND active_value  = TRUE
        AND r.depth_level = _cur_level
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
            indicator_variables_variation_id, valid_from, user_id, value_of_date, value, generated_by_compute, active_value )
    SELECT x.upper_region,
                x.indicator_variation_id,
                x.indicator_variables_variation_id,
                x.valid_from,
                x.user_id,
                x.valid_from,
                x.total::varchar,
                TRUE,
                TRUE
    FROM _x x;

    -- removendo temp table, por causa dos testes que rodam na mesma transection.
    DROP TABLE _x;
    DROP TABLE sum_data;

    -- ok
    RETURN TRUE;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

truncate indicator_value;

DROP INDEX IF EXISTS ix_indicator_value__value_unique ;
DROP INDEX IF EXISTS ix_indicator_value__value_unique_region;


CREATE UNIQUE INDEX ix_indicator_value__value_unique
  ON indicator_value
  USING btree
  (indicator_id, valid_from, user_id, variation_name COLLATE pg_catalog."default")
  WHERE region_id IS NULL;


CREATE UNIQUE INDEX ix_indicator_value__value_unique_region
  ON indicator_value
  USING btree
  (indicator_id, valid_from, user_id, variation_name COLLATE pg_catalog."default", region_id)
  WHERE region_id IS NOT NULL;

alter table indicator_value drop column active_value cascade;
alter table indicator_value drop column generated_by_compute cascade;


alter table indicator_value add column values_used varchar;

alter table end_user_indicator_queue drop column active_value cascade;
alter table end_user_indicator_queue drop column generated_by_compute cascade;

alter table end_user_indicator_queue add column values_used varchar;



CREATE OR REPLACE FUNCTION f_add_indicator_value_to_end_user_queue()
  RETURNS trigger AS
$BODY$
DECLARE
     r record;
    BEGIN

        IF (TG_OP = 'DELETE') THEN
            r := OLD;
        ELSIF (TG_OP = 'INSERT') THEN
            r := NEW;
        END IF;

        INSERT INTO end_user_indicator_queue (
            end_user_id,
            operation_type,

            indicator_id,
            valid_from,
            user_id,
            city_id,
            institute_id,
            region_id,
            value,
            variation_name,
            sources,
            values_used
        )
        SELECT
            eui.end_user_id,
            TG_OP,

            (r.indicator_id),
            (r.valid_from),
            (r.user_id),
            (r.city_id),
            (r.institute_id),
            (r.region_id),
            (r.value),
            (r.variation_name),
            (r.sources),
            r.values_used

        FROM end_user_indicator eui
        LEFT JOIN end_user_indicator_user euiu
            ON euiu.end_user_indicator_id = eui.id AND euiu.user_id = r.user_id
        WHERE
            eui.indicator_id = r.indicator_id
        AND (eui.all_users = TRUE OR euiu.id IS NOT NULL );

      return NULL;
    END;
 $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- nunca retornar um ano maior do que o ano atual, mesmo se encontrar na tabela..
CREATE OR REPLACE FUNCTION voltar_periodo(p_date timestamp without time zone, p_period period_enum, p_num integer)
  RETURNS date AS
$BODY$DECLARE

BEGIN
    p_date := LEAST( coalesce(
        p_date,
        ( select max(valid_from) from variable_value
          where variable_id in (select id from variable where period = p_period)
        ),
        current_date
    ), current_date);


    IF (p_period IN ('weekly', 'monthly', 'yearly', 'decade') ) THEN
            RETURN date_trunc(replace(p_period::text, 'ly',''), (p_date - ( p_num::text|| ' ' || replace(p_period::text, 'ly','') )::interval  )::date);
    ELSEIF (p_period = 'daily') THEN
        RETURN ( p_date - '1 day'::interval  )::date;
    ELSEIF (p_period = 'bimonthly') THEN
        RETURN date_trunc('month', ( p_date - ( (p_num*2)::text|| ' month' )::interval  )::date);
    ELSEIF (p_period = 'quarterly') THEN
        RETURN date_trunc('month',( p_date - ( (p_num*3)::text|| ' month' )::interval  )::date);
    ELSEIF (p_period = 'semi-annual') THEN
        RETURN date_trunc('month',( p_date - ( (p_num*6)::text|| ' month' )::interval  )::date);
    END IF;

    RETURN NULL;
END;$BODY$
  LANGUAGE plpgsql STABLE
  COST 1;



CREATE OR REPLACE VIEW download_data AS
SELECT m.city_id,
       c.name AS city_name,
       e.name AS axis_name,
       m.indicator_id,
       i.name AS indicator_name,
       i.formula_human,
       i.formula,
       i.goal,
       i.goal_explanation,
       i.goal_source,
       i.goal_operator,
       i.explanation,
       i.tags,
       i.observations,
       i.period,
       m.variation_name,
       iv.order as variation_order,
       m.valid_from,
       m.value,
       a.goal AS user_goal,
       a.justification_of_missing_field,
       t.technical_information,
       m.institute_id,
       m.user_id,
       m.region_id,
       m.sources,
       r.name AS region_name,
       m.updated_at
FROM indicator_value m
JOIN city AS c ON m.city_id = c.id
JOIN indicator AS i ON i.id = m.indicator_id
LEFT JOIN axis AS e ON e.id = i.axis_id
LEFT JOIN indicator_variations iv on (case when m.variation_name = '' THEN FALSE ELSE (iv.name = m.variation_name AND iv.indicator_id = m.indicator_id AND iv.user_id IN (m.user_id, i.user_id)) END)
LEFT JOIN user_indicator a ON a.user_id = m.user_id AND a.valid_from = m.valid_from AND a.indicator_id = m.indicator_id
LEFT JOIN user_indicator_config t ON t.user_id = m.user_id AND t.indicator_id = i.id
LEFT JOIN region r ON r.id = m.region_id;

























COMMIT;
