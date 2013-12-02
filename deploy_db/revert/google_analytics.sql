-- Revert google_analytics

BEGIN;

alter table network drop ga_account ;


COMMIT;
