-- Revert indicators-permissions

BEGIN;

alter table institute drop column can_create_indicators ;

alter table "user" drop column can_create_indicators;

alter table institute drop column fixed_indicator_axis_id;

COMMIT;
