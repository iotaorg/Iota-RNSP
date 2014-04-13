-- Deploy sum-by-regions-only-necessary-data
-- requires: appschema

BEGIN;

DROP FUNCTION compute_upper_regions(integer[]);

CREATE OR REPLACE FUNCTION compute_upper_regions(_ids integer[], _var_ids integer[], _variation_var_ids integer[], dates date[]) RETURNS integer[] AS $BODY$DECLARE v_ret int[]; BEGIN
CREATE TEMP TABLE _x AS
SELECT r.upper_region,
       iv.valid_from,
       iv.user_id,
       iv.variable_id,
       sum(iv.value::numeric) AS total,
       ARRAY
  (SELECT DISTINCT UNNEST(array_agg(iv.source))
   ORDER BY 1) AS sources
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
  AND v.type IN ('int',
                 'num')
GROUP BY 1,
         2,
         3,
         4;
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
     FROM _x )
  AND generated_by_compute = TRUE;
  INSERT INTO region_variable_value ( region_id, variable_id, valid_from, user_id, value_of_date, value, SOURCE, generated_by_compute )
  SELECT x.upper_region,
         x.variable_id,
         x.valid_from,
         x.user_id,
         x.valid_from,
         x.total::varchar,
         x.sources[1],
         TRUE
  FROM _x x;
  SELECT ARRAY
    (SELECT upper_region
     FROM _x
     GROUP BY 1) INTO v_ret;
  DROP TABLE _x;
  CREATE TEMP TABLE _x AS
  SELECT r.upper_region,
         iv.valid_from,
         iv.user_id,
         iv.indicator_variation_id,
         iv.indicator_variables_variation_id,
         sum(iv.value::numeric) AS total
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
  AND v.type IN ('int',
                 'num')
GROUP BY 1,
         2,
         3,
         4,
         5;
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
     FROM _x )
  AND generated_by_compute = TRUE;
  INSERT INTO indicator_variables_variations_value ( region_id, indicator_variation_id, indicator_variables_variation_id, valid_from, user_id, value_of_date, value, generated_by_compute )
  SELECT x.upper_region,
         x.indicator_variation_id,
         x.indicator_variables_variation_id,
         x.valid_from,
         x.user_id,
         x.valid_from,
         x.total::varchar,
         TRUE
  FROM _x x;
  DROP TABLE _x; RETURN v_ret; END; $BODY$ LANGUAGE plpgsql VOLATILE COST 100;

COMMIT;
