-- Deploy fix-volta-periodo
-- requires: appschema

BEGIN;

CREATE OR REPLACE FUNCTION voltar_periodo(p_date timestamp without time zone, p_period period_enum, p_num integer)
  RETURNS date AS
$BODY$DECLARE

BEGIN
    p_date := coalesce(
        p_date,
        ( select max(valid_from) from variable_value
          where variable_id in (select id from variable where period = p_period)
        ),
        current_date
    );


    IF (p_period IN ('weekly', 'monthly', 'yearly', 'decade') ) THEN
            RETURN date_trunc(replace(p_period::text, 'ly',''), (p_date - ( p_num::text|| ' ' || replace(p_period::text, 'ly','') )::interval  )::date);
    ELSEIF (p_period = 'daily') THEN
        RETURN ( p_date - '1 day'::interval  )::date;
    ELSEIF (p_period = 'bimonthly') THEN
        RETURN date_trunc('month', ( p_date - ( (p_num*2)::text|| ' month' )::interval  )::date);
    ELSEIF (p_period = 'quarterly') THEN
        RETURN date_trunc('month',( p_date - ( (p_num*3)::text|| ' month' )::interval  )::date);
    ELSEIF (p_period = 'semi-annual') THEN
        RETURN date_trunc('month',( p_date - ( (p_num*6)::text|| ' month' )::interval  )::date);
    END IF;

    RETURN NULL;
END;$BODY$
  LANGUAGE plpgsql STABLE
  COST 100;


COMMIT;
