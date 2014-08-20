-- Deploy 0056-download-data-with-values
-- requires: 0055-update-compute-upper-regions

BEGIN;

drop view download_data;
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
       m.updated_at,
       m.values_used
FROM indicator_value m
JOIN city AS c ON m.city_id = c.id
JOIN indicator AS i ON i.id = m.indicator_id
LEFT JOIN axis AS e ON e.id = i.axis_id
LEFT JOIN indicator_variations iv on (case when m.variation_name = '' THEN FALSE ELSE (iv.name = m.variation_name AND iv.indicator_id = m.indicator_id AND iv.user_id IN (m.user_id, i.user_id)) END)
LEFT JOIN user_indicator a ON a.user_id = m.user_id AND a.valid_from = m.valid_from AND a.indicator_id = m.indicator_id
LEFT JOIN user_indicator_config t ON t.user_id = m.user_id AND t.indicator_id = i.id
LEFT JOIN region r ON r.id = m.region_id;


COMMIT;
