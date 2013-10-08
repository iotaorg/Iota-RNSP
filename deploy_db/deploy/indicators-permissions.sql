-- Deploy indicators-permissions
-- requires: appschema

BEGIN;

alter table institute add column can_create_indicators boolean not null default false;

alter table institute add column fixed_indicator_axis_id int;

alter table "user" add column can_create_indicators boolean not null default false;

COMMIT;
