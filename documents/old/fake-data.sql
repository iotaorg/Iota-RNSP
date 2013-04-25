delete from variable_value where user_id=102;

insert into variable_value (
value, variable_id, user_id, created_at,value_of_date,valid_from,valid_until
)

select ("value"::numeric * random()::numeric)::text, variable_id, 102, created_at,value_of_date,valid_from,valid_until from variable_value where user_id=11;

insert into variable_value (
value, variable_id, user_id, created_at,value_of_date,valid_from,valid_until
)
select ("value"::numeric * random()::numeric)::text, variable_id, 102, created_at,value_of_date+'1 year'::interval,valid_from+'1 year'::interval,valid_until+'1 year'::interval from variable_value where user_id=11
and valid_from='2011-01-01'::date
and variable_id not in (select variable_id from variable_value where user_id=102 and valid_from::date = '2012-01-01');

update variable_value set value = value::numeric/ 2 where user_id=102 and variable_id in (select id from variable where is_basic )


