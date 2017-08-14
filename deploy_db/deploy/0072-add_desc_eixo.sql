-- Deploy iota:0072-add_desc_eixo to pg
-- requires: 0071-new-tables

BEGIN;

alter table axis add column description varchar;

COMMIT;
