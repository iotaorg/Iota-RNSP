-- Revert permissions-for-regions

BEGIN;


alter table institute drop column can_use_regions;

alter table "user" drop column regions_enabled;


COMMIT;
