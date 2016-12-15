-- Deploy iota:0068-metadata_on_institute to pg
-- requires: 0067-region-trigger

BEGIN;

alter table institute add column metadata varchar;

COMMIT;
