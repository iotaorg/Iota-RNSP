-- Deploy 0059-compute_upper_regions-active-value-fix
-- requires: 0058-auto-add-lex

BEGIN;

alter table region_variable_value add column end_ts timestamp not null default 'infinity';

DROP INDEX IF EXISTS ix_region_variable_value;

CREATE UNIQUE INDEX ix_region_variable_value
  ON region_variable_value
  USING btree
  (variable_id, user_id, valid_from, active_value)
  WHERE region_id IS NULL AND end_ts = 'infinity';


DROP INDEX IF EXISTS ix_region_variable_value_region;

CREATE UNIQUE INDEX ix_region_variable_value_region
  ON region_variable_value
  USING btree
  (variable_id, user_id, valid_from, active_value, region_id)
  WHERE region_id IS NOT NULL AND end_ts = 'infinity';

DROP INDEX IF EXISTS region_variable_value_idx_cloned_from_user;

CREATE INDEX region_variable_value_idx_cloned_from_user
  ON region_variable_value
  USING btree
  (cloned_from_user) WHERE end_ts = 'infinity';

DROP INDEX IF EXISTS region_variable_value_idx_region_id;

CREATE INDEX region_variable_value_idx_region_id
  ON region_variable_value
  USING btree
  (region_id) where end_ts = 'infinity';

DROP INDEX IF EXISTS region_variable_value_idx_user_id;

CREATE INDEX region_variable_value_idx_user_id
  ON region_variable_value
  USING btree
  (user_id) where end_ts = 'infinity';

DROP INDEX IF EXISTS region_variable_value_idx_variable_id;

CREATE INDEX region_variable_value_idx_variable_id
  ON region_variable_value
  USING btree
  (variable_id) where end_ts = 'infinity';

-- duplicada?
ALTER TABLE region_variable_value DROP CONSTRAINT region_variable_value_region_id_variable_id_user_id_valid_f_key;

-------

alter table indicator_variables_variations_value add column end_ts timestamp not null default 'infinity';

DROP INDEX IF EXISTS  ix_indicator_variables_variations_value_region;

CREATE UNIQUE INDEX ix_indicator_variables_variations_value_region
  ON indicator_variables_variations_value
  USING btree
  (indicator_variation_id, indicator_variables_variation_id, valid_from, user_id, active_value, region_id)
  WHERE region_id IS NOT NULL AND end_ts = 'infinity';

DROP INDEX IF EXISTS ix_indicator_variables_variations_value_region;

CREATE UNIQUE INDEX ix_indicator_variables_variations_value_region
  ON indicator_variables_variations_value
  USING btree
  (indicator_variation_id, indicator_variables_variation_id, valid_from, user_id, active_value, region_id)
  WHERE region_id IS NOT NULL AND end_ts = 'infinity';

---------------

CREATE OR REPLACE FUNCTION compute_upper_regions(_ids integer[], _var_ids integer[], _var_variation_ids integer[], _dates date[], _cur_level integer)
  RETURNS boolean AS
$BODY$
declare items record;
BEGIN

    -- faz a soma das variaveis comuns
    CREATE TEMP TABLE sum_data AS
    SELECT  r.upper_region,
                iv.valid_from,
                iv.user_id,
                iv.variable_id,

                iv.active_value,
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

            AND r.depth_level = _cur_level
            AND v.type IN ('int', 'num')
        GROUP BY 1,
                2,
                3,
                4, active_value, v.summarization_method;

    CREATE TEMP TABLE _x AS
    SELECT
        sum_data.*
    FROM sum_data
    JOIN "user" u ON sum_data.user_id = u.id
    JOIN institute it ON it.id = u.institute_id
    WHERE CASE WHEN it.aggregate_only_if_full THEN qtde_regions = total_regions ELSE TRUE END;

/*
raise notice '_cur_level => % ', _cur_level;

raise notice 'aggregate_only_if_full => _x ';

 FOR items IN select * from _x LOOP
    RAISE NOTICE 'active_value: %, region_id: %, user_id: %, valid_from: %, variable_id: %, total: %',
    (items.active_value),
    (items.upper_region),
    (items.user_id),
    (items.valid_from),
    (items.variable_id),
    (items.total);
END LOOP;
*/
    -- apaga as existentes
    DELETE
    FROM region_variable_value
    WHERE (active_value, region_id,
            user_id,
            valid_from,
            variable_id) IN
        ( SELECT active_value, upper_region,
                        user_id,
                        valid_from,
                        variable_id
        FROM sum_data )
    AND generated_by_compute = TRUE;

    drop table sum_data;

    -- atualiza o end_ts para os valores que ja estavam la..
    UPDATE region_variable_value
    SET end_ts = now()
    WHERE (active_value, region_id,
            user_id,
            valid_from,
            variable_id) IN
        ( SELECT active_value, upper_region,
                        user_id,
                        valid_from,
                        variable_id
        FROM _x WHERE active_value = FALSE )
    AND active_value = FALSE;
    /*
raise notice 'active_value false => _x ';

 FOR items IN select * from _x where active_value = false LOOP
    RAISE NOTICE 'active_value false, region_id: %, user_id: %, valid_from: %, variable_id: %, total: %',
        (items.upper_region),
    (items.user_id),
    (items.valid_from),
    (items.variable_id),
    (items.total);
END LOOP;
*/
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
                active_value
    FROM _x x;

    DROP TABLE _x;

    -- agora vamos fazer a soma das variaveis de variacoes
    CREATE TEMP TABLE sum_data AS
     SELECT r.upper_region,
                iv.valid_from,
                iv.user_id,
                iv.indicator_variation_id,
                iv.indicator_variables_variation_id,

                iv.active_value,
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

        AND r.depth_level = _cur_level
        AND v.type IN ('int', 'num')

        GROUP BY 1,
                2,
                3,
                4,
                5, iv.active_value, v.summarization_method;

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
    WHERE (active_value, region_id,
            user_id,
            valid_from,
            indicator_variation_id,
            indicator_variables_variation_id) IN
        ( SELECT active_value, upper_region,
                        user_id,
                        valid_from,
                        indicator_variation_id,
                        indicator_variables_variation_id
        FROM sum_data )
    AND generated_by_compute = TRUE;

   -- atualiza o end_ts para os valores que ja estavam la..
    UPDATE indicator_variables_variations_value
    SET end_ts = NOW()
    WHERE (active_value, region_id,
            user_id,
            valid_from,
            indicator_variation_id,
            indicator_variables_variation_id) IN
        ( SELECT active_value, upper_region,
                        user_id,
                        valid_from,
                        indicator_variation_id,
                        indicator_variables_variation_id
        FROM sum_data WHERE active_value = FALSE);

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
                x.active_value
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



COMMIT;
