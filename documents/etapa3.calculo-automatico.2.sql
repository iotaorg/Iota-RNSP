-- campos para indicadar que um dado foi salvo automaticamente e
-- qual dado deve ser usado
alter table indicator_value add column active_value boolean not null default true;
alter table indicator_value add column generated_by_compute boolean not null default false;
create index ix_indicator_value__active_value on indicator_value(active_value);

ALTER TABLE region
  ADD UNIQUE (city_id, name_url);


------- adicionado dia 28






alter table region_variable_value add column generated_by_compute boolean;
alter table region_variable_value add column active_value boolean not null default true;
update region_variable_value set active_value = true;


ALTER TABLE region_variable_value DROP CONSTRAINT region_variable_value_region_id_variable_id_user_id_valid_f_key;

ALTER TABLE region_variable_value
  ADD CONSTRAINT region_variable_value_region_id_variable_id_user_id_valid_f_key UNIQUE(region_id, variable_id, user_id, valid_from, active_value);



alter table indicator_variables_variations_value add column generated_by_compute boolean;
alter table indicator_variables_variations_value add column active_value boolean not null default true;


ALTER TABLE indicator_variables_variations_value DROP CONSTRAINT indicator_variables_variation_indicator_variation_id_indica_key;

ALTER TABLE indicator_variables_variations_value
  ADD CONSTRAINT indicator_variables_variation_indicator_variation_id_indica_key UNIQUE(indicator_variation_id, indicator_variables_variation_id, valid_from, user_id, active_value);


ALTER TABLE indicator_variables_variations_value DROP CONSTRAINT indicator_variables_variation_indicator_variation_id_indica_key;

CREATE UNIQUE INDEX on indicator_variables_variations_value(indicator_variation_id, indicator_variables_variation_id, valid_from, user_id, active_value)
  WHERE region_id is null;

CREATE UNIQUE INDEX on indicator_variables_variations_value(indicator_variation_id, indicator_variables_variation_id, valid_from, user_id, region_id, active_value)
  WHERE region_id is not null;


