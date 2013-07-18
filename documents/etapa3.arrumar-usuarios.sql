CREATE TABLE network_user
(
  network_id integer NOT NULL,
  user_id integer NOT NULL,
  CONSTRAINT network_user_pkey PRIMARY KEY (user_id, network_id),
  CONSTRAINT network_user_network_id_fkey FOREIGN KEY (network_id)
      REFERENCES network (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT network_user_user_id_fkey FOREIGN KEY (user_id)
      REFERENCES "user" (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

alter table "user" rename network_id to _network_id  ;

alter table "user" add institute_id int;
ALTER TABLE "user"
  ADD FOREIGN KEY (institute_id) REFERENCES institute (id) ON UPDATE NO ACTION ON DELETE NO ACTION;

insert into network_user(user_id, network_id)
select id, _network_id from "user" where _network_id is not null;

update "user" a set institute_id = b.institute_id from network b where b.id = a._network_id;

alter table "user" drop column _network_id cascade;


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
    i.id as institute_id

from variable_value vv
join variable v on v.id = vv.variable_id
left join measurement_unit m on m.id = v.measurement_unit_id
join "user" u on u.id = vv.user_id
join network_user nu on nu.user_id = u.id
join network n on n.id = nu.network_id
join institute i on i.id = n.institute_id
join city c on c.id = u.city_id
--where value is not null and value != ''
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
    i.id as institute_id

from indicator_variables_variations_value vv
join indicator_variations vvv on vvv.id = indicator_variation_id
join indicator_variables_variations v on v.id = vv.indicator_variables_variation_id
join indicator ix on ix.id = vvv.indicator_id
join "user" u on u.id = vv.user_id
join network_user nu on nu.user_id = u.id
join network n on n.id = nu.network_id
join institute i on i.id = n.institute_id
join city c on c.id = u.city_id
--where value is not null and value != '';