-- Deploy iota:0064-topic-network to pg
-- requires: 0063-fix-type

BEGIN;

	ALTER TABLE network add column topic boolean default false;

COMMIT;
