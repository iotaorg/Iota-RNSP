-- Deploy iota:0063-fix-type to pg
-- requires: 0062-observations

BEGIN;


alter table network add column topic boolean default false;

COMMIT;
