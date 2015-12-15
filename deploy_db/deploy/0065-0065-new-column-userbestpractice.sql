-- Deploy iota:0065-0065-new-column-userbestpractice to pg
-- requires: 0064-topic-network

BEGIN;

-- XXX Add DDLs here.
ALTER TABLE USER_BEST_PRATICE ADD COLUMN repercussion text;


COMMIT;
