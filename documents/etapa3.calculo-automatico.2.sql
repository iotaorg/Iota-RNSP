-- campos para indicadar que um dado foi salvo automaticamente e
-- qual dado deve ser usado
alter table indicator_value add column active_value boolean not null default true;
alter table indicator_value add column generated_by_compute boolean not null default false;
create index ix_indicator_value__active_value on indicator_value(active_value);

ALTER TABLE region
  ADD UNIQUE (city_id, name_url);
