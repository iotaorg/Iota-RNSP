-- Deploy 0060-campos-para-rdf
-- requires: 0059-compute_upper_regions-active-value-fix

BEGIN;


-- apenas um registro, que precisa ser TRUE ou N nulls.
alter table network add column rdf_identifier boolean;

ALTER TABLE network
  ADD CHECK (rdf_identifier != false);
ALTER TABLE network
  ADD UNIQUE (rdf_identifier);

-- diz q o primeiro eh o primeiro é o principal.
update network set rdf_identifier = true where id = (select min (id) from network );

COMMIT;
