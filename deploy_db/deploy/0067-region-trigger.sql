-- Deploy iota:0067-region-trigger to pg
-- requires: 0066-fix-download-view

BEGIN;


CREATE OR REPLACE FUNCTION f_fix_null_regions() RETURNS TRIGGER AS $$
BEGIN
    NEW.polygon_path := case when (NEW.polygon_path in ('null', 'null@@')) then '' else NEW.polygon_path end;

    RETURN NEW;
END;
$$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public;

-- Criando a trigger.
CREATE TRIGGER t_fix_region_null
  BEFORE INSERT OR UPDATE ON region
  FOR EACH ROW EXECUTE PROCEDURE f_fix_null_regions();


update region set name=name;


COMMIT;
