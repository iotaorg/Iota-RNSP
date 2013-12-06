-- Deploy variable_summarization
-- requires: appschema

BEGIN;



CREATE OR REPLACE FUNCTION compute_upper_regions(_ids integer[])
  RETURNS integer[] AS
$BODY$DECLARE
v_ret int[];
BEGIN
    create temp table _x as
    select
     r.upper_region,
     iv.valid_from,
     iv.user_id,
     iv.variable_id,

     case when v.summarization_method = 'sum' then sum(iv.value::numeric) else avg(iv.value::numeric) end as total,
     ARRAY(SELECT DISTINCT UNNEST( array_agg(iv.source) ) ORDER BY 1)  as sources

    from region r
    join region_variable_value iv on iv.region_id = r.id
    join variable v on iv.variable_id = v.id

    where r.upper_region in (
        select upper_region from region x where x.id in (SELECT unnest($1)) and x.depth_level= 3
    )
    and active_value = true
    and r.depth_level = 3

    and v.type in ('int', 'num')
    group by 1,2,3,4,v.summarization_method;

    delete from region_variable_value where (region_id, user_id, valid_from, variable_id) IN (
        SELECT upper_region, user_id, valid_from, variable_id from _x
    ) AND generated_by_compute = TRUE;

    insert into region_variable_value (
        region_id,
        variable_id,
        valid_from,
        user_id,
        value_of_date,
        value,
        source,
        generated_by_compute
    )
    select
        x.upper_region,
        x.variable_id,
        x.valid_from,
        x.user_id,
        x.valid_from,

        x.total::varchar,
        x.sources[1],
        true
    from _x x;

    select ARRAY(select upper_region from _x group by 1) into v_ret;
    drop table _x;

    create temp table _x as
    select
     r.upper_region,
     iv.valid_from,
     iv.user_id,
     iv.indicator_variation_id,
     iv.indicator_variables_variation_id,

     case when v.summarization_method = 'sum' then sum(iv.value::numeric) else avg(iv.value::numeric) end as total


    from region r
    join indicator_variables_variations_value iv on iv.region_id = r.id
    join indicator_variables_variations v on iv.indicator_variables_variation_id = v.id

    where r.upper_region in (
    select upper_region from region x where x.id in (SELECT unnest($1)) and x.depth_level= 3
    )
    and active_value = true
    and r.depth_level= 3

    and v.type in ('int', 'num')
    group by 1,2,3,4,5, v.summarization_method;

    delete from indicator_variables_variations_value where (region_id, user_id, valid_from, indicator_variation_id, indicator_variables_variation_id) IN (
        SELECT upper_region, user_id, valid_from, indicator_variation_id, indicator_variables_variation_id from _x
    ) AND generated_by_compute = TRUE;

    insert into indicator_variables_variations_value (
        region_id,
        indicator_variation_id,
        indicator_variables_variation_id,
        valid_from,
        user_id,
        value_of_date,
        value,
        generated_by_compute
    )
    select
        x.upper_region,
        x.indicator_variation_id,
        x.indicator_variables_variation_id,
        x.valid_from,
        x.user_id,
        x.valid_from,

        x.total::varchar,
        true
    from _x x;


    drop table _x;
    return v_ret;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

alter table variable add summarization_method character varying NOT NULL DEFAULT 'sum'::character varying;
alter table indicator_variables_variations add summarization_method character varying NOT NULL DEFAULT 'sum'::character varying;

update  variable set  summarization_method  = 'avg' where id = (select id from variable where name like '%ndice de Desenvolvimento da Educação Básica%Rede municipal de 5ª a 8ª série%');


select compute_upper_regions( ARRAY(select id from region where depth_level = 3 )::int[] );


COMMIT;
