-- Deploy iota:0080-fix-source-insertion to pg
-- requires: 0079-variable_image

BEGIN;


CREATE OR REPLACE FUNCTION source_find_or_new(
    xsource varchar,
    xuser_id integer)
  RETURNS int  AS
$BODY$DECLARE
DECLARE
v_ret int;
BEGIN

    SELECT id FROM "source" WHERE lower(name) = lower(xsource) COLLATE pg_catalog."default" INTO v_ret ;
        IF NOT FOUND THEN
        INSERT INTO source (name, user_id) values (xsource, xuser_id) returning id INTO v_ret ;
        END IF;

    RETURN v_ret ;
END;$BODY$
  LANGUAGE plpgsql
  COST 1;

COMMIT;
