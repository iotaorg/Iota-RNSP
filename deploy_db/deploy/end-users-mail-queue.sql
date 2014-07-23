-- Deploy end-users-mail-queue
-- requires: end-users-by-network

BEGIN;

create table end_user_indicator_queue (
    id bigserial not null primary key,

    created_at timestamp not null default now(),

    end_user_id int not null,

    email_sent boolean not null default false,


    -- insert / delete
    operation_type varchar not null,

    indicator_id integer NOT NULL,
    valid_from date NOT NULL,
    user_id integer NOT NULL,
    city_id integer,
    institute_id integer NOT NULL,
    region_id integer,
    value character varying NOT NULL,
    variation_name character varying NOT NULL DEFAULT ''::character varying,
    sources character varying[],
    active_value boolean NOT NULL DEFAULT true,
    generated_by_compute boolean NOT NULL DEFAULT false

);

ALTER TABLE end_user_indicator_queue
  ADD FOREIGN KEY (end_user_id) REFERENCES end_user (id) ON UPDATE cascade ON DELETE cascade;




CREATE OR REPLACE FUNCTION f_add_indicator_value_to_end_user_queue() RETURNS TRIGGER AS $body$
DECLARE
     r record;
    BEGIN

        IF (TG_OP = 'DELETE') THEN
            r := OLD;
        ELSIF (TG_OP = 'INSERT') THEN
            r := NEW;
        END IF;

        INSERT INTO end_user_indicator_queue (
            end_user_id,
            operation_type,

            indicator_id,
            valid_from,
            user_id,
            city_id,
            institute_id,
            region_id,
            value,
            variation_name,
            sources,
            active_value,
            generated_by_compute
        )
        SELECT
            eui.end_user_id,
            TG_OP,

            (r.indicator_id),
            (r.valid_from),
            (r.user_id),
            (r.city_id),
            (r.institute_id),
            (r.region_id),
            (r.value),
            (r.variation_name),
            (r.sources),
            (r.active_value),
            (r.generated_by_compute)

        FROM end_user_indicator eui
        LEFT JOIN end_user_indicator_user euiu
            ON euiu.end_user_indicator_id = eui.id AND euiu.user_id = r.user_id
        WHERE
            eui.indicator_id = r.indicator_id
        AND (eui.all_users = TRUE OR euiu.id IS NOT NULL );

      return NULL;
    END;
 $body$ LANGUAGE plpgsql;


CREATE TRIGGER tg_add_indicator_value_to_end_user_queue
    AFTER INSERT OR DELETE ON indicator_value
    FOR EACH ROW
    EXECUTE PROCEDURE f_add_indicator_value_to_end_user_queue();





COMMIT;
