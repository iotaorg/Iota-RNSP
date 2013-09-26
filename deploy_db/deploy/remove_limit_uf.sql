-- Deploy remove_limit_uf
-- requires: appschema

BEGIN;

ALTER TABLE city
   ALTER COLUMN uf TYPE varchar;

COMMIT;
