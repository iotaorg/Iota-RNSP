-- Deploy permissions-for-regions
-- requires: appschema

BEGIN;

alter table institute add column can_use_regions boolean not null default false;

alter table "user" add column regions_enabled boolean not null default false;

COMMIT;
