-- Deploy iota:0076-DownloadData to pg
-- requires: 0075-axis4

BEGIN;
DROP VIEW public.download_data;

CREATE OR REPLACE VIEW public.download_data AS
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
    iv."order" AS variation_order,
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
    m.values_used,
    d1.name as axis_aux1,
    d2.name as axis_aux2,
    d3.description as axis_aux3
   FROM indicator_value m
     JOIN city c ON m.city_id = c.id
     JOIN indicator i ON i.id = m.indicator_id
     LEFT JOIN axis e ON e.id = i.axis_id
     LEFT JOIN axis_dim1 d1 ON d1.id = i.axis_dim1_id
     LEFT JOIN axis_dim2 d2 ON d2.id = i.axis_dim2_id
     LEFT JOIN axis_dim3 d3 ON d3.id = i.axis_dim3_id

     LEFT JOIN indicator_variations iv ON
        CASE
            WHEN m.variation_name::text = ''::text THEN false
            ELSE iv.name::text = m.variation_name::text AND iv.indicator_id = m.indicator_id AND (iv.user_id = m.user_id OR iv.user_id = i.user_id)
        END
     LEFT JOIN user_indicator a ON a.user_id = m.user_id AND a.valid_from = m.valid_from AND a.indicator_id = m.indicator_id
     LEFT JOIN user_indicator_config t ON t.user_id = m.user_id AND t.indicator_id = i.id
     LEFT JOIN region r ON r.id = m.region_id;

COMMIT;
