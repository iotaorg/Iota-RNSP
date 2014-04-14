-- Deploy invisible-indicador-for-basic-variables
-- requires: sum-by-regions-only-necessary-data-fix

BEGIN;

alter table indicator add column is_fake boolean not null default false;

COMMIT;
