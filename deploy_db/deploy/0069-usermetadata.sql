-- Deploy iota:0069-usermetadata to pg
-- requires: 0068-metadata_on_institute

BEGIN;

alter table "user" add column metadata;

COMMIT;
