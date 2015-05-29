-- Deploy iota:0062-observations to pg
-- requires: 0061-unique-sources-per-user

BEGIN;


alter table indicator_value add column observations varchar;

COMMIT;
