-- Deploy google_analytics
-- requires: appschema

BEGIN;

alter table network add ga_account varchar;


COMMIT;
