-- Revert remove_limit_uf

BEGIN;

ALTER TABLE city
   ALTER COLUMN uf TYPE character(2);

COMMIT;
