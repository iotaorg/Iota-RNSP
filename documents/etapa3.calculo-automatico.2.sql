-- campos para indicadar que um dado foi salvo automaticamente e
-- qual dado deve ser usado
alter table indicator_value add column active_value boolean not null default true;
alter table indicator_value add column generated_by_compute boolean not null default false;
create index ix_indicator_value__active_value on indicator_value(active_value);

ALTER TABLE region
  ADD UNIQUE (city_id, name_url);


------- adicionado dia 28

alter table variable_value add column generated_by_compute boolean;
alter table variable_value add column active_value boolean default true;
update variable_value set active_value = true;
ALTER TABLE variable_value DROP CONSTRAINT user_value_period_key;

ALTER TABLE variable_value
  ADD CONSTRAINT user_value_period_key UNIQUE(variable_id, user_id, valid_from, active_value);

alter table region_variable_value add column generated_by_compute boolean;
alter table region_variable_value add column active_value boolean default true;
update region_variable_value set active_value = true;


ALTER TABLE region_variable_value DROP CONSTRAINT region_variable_value_region_id_variable_id_user_id_valid_f_key;

ALTER TABLE region_variable_value
  ADD CONSTRAINT region_variable_value_region_id_variable_id_user_id_valid_f_key UNIQUE(region_id, variable_id, user_id, valid_from, active_value);

