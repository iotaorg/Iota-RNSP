-- Deploy iota:0063-fix-type to pg
-- requires: 0062-observations

BEGIN;


alter table indicator_value alter observations type varchar[] using observations::text[];

COMMIT;
