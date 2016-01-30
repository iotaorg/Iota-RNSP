-- Deploy iota:0066-fix-download-view to pg
-- requires: 0065-0065-new-column-userbestpractice

BEGIN;

CREATE  or replace VIEW download_variable AS
SELECT

    c.id as city_id,
    c.name as city_name,
    v.id as variable_id,
    v.type,
    v.cognomen,
    v.period::varchar,
    v.source as exp_source,
    v.is_basic,
    m.name as measurement_unit_name,
    v.name,
    vv.valid_from,
    vv.value,
    vv.observations,
    vv.source,
    vv.user_id,
    i.id as institute_id,
    vv.created_at as updated_at
from variable_value vv
join variable v on v.id = vv.variable_id
left join measurement_unit m on m.id = v.measurement_unit_id
join "user" u on u.id = vv.user_id
join institute i on i.id = u.institute_id
join city c on c.id = u.city_id
union all
SELECT

    c.id as city_id,
    c.name as city_name,
    -vvv.id as variable_id,
    v.type,
    v.name as cognomen,
    ix.period::varchar as period,
    null as exp_source,
    null as is_basic,
    null as measurement_unit_name,
    vvv.name || ': ' || v.name as name,
    vv.valid_from,
    vv.value,
    null as observations,
    null as source,
    vv.user_id,
    i.id as institute_id,
    vv.created_at as updated_at

from indicator_variables_variations_value vv
join indicator_variations vvv on vvv.id = indicator_variation_id
join indicator_variables_variations v on v.id = vv.indicator_variables_variation_id
join indicator ix on ix.id = vvv.indicator_id
join "user" u on u.id = vv.user_id
join institute i on i.id = u.institute_id
join city c on c.id = u.city_id
active_value = TRUE;

COMMIT;
