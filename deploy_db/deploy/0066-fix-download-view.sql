-- Deploy iota:0066-fix-download-view to pg
-- requires: 0065-0065-new-column-userbestpractice

BEGIN;

CREATE  or replace VIEW download_variable AS
SELECT c.id AS city_id,
    c.name AS city_name,
    v.id AS variable_id,
    v.type,
    v.cognomen,
    v.period::character varying AS period,
    v.source AS exp_source,
    v.is_basic,
    m.name AS measurement_unit_name,
    v.name,
    vv.valid_from,
    vv.value,
    vv.observations,
    vv.source,
    vv.user_id,
    i.id AS institute_id,
    vv.created_at AS updated_at
   FROM variable_value vv
     JOIN variable v ON v.id = vv.variable_id
     LEFT JOIN measurement_unit m ON m.id = v.measurement_unit_id
     JOIN "user" u ON u.id = vv.user_id
     JOIN institute i ON i.id = u.institute_id
     JOIN city c ON c.id = u.city_id
UNION ALL
 SELECT c.id AS city_id,
    c.name AS city_name,
    - vvv.id AS variable_id,
    v.type,
    v.name AS cognomen,
    ix.period,
    NULL::text AS exp_source,
    NULL::boolean AS is_basic,
    NULL::character varying AS measurement_unit_name,
    (vvv.name::text || ': '::text) || v.name::text AS name,
    vv.valid_from,
    vv.value,
    NULL::character varying AS observations,
    NULL::character varying AS source,
    vv.user_id,
    i.id AS institute_id,
    vv.created_at AS updated_at
   FROM indicator_variables_variations_value vv
     JOIN indicator_variations vvv ON vvv.id = vv.indicator_variation_id
     JOIN indicator_variables_variations v ON v.id = vv.indicator_variables_variation_id
     JOIN indicator ix ON ix.id = vvv.indicator_id
     JOIN "user" u ON u.id = vv.user_id
     JOIN institute i ON i.id = u.institute_id
     JOIN city c ON c.id = u.city_id
  WHERE vv.active_value = true;


COMMIT;
