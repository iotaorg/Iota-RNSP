
CREATE TABLE indicator_values
(
    id integer NOT NULL,
    indicator_id integer NOT NULL,
    valid_from date NOT NULL,
    user_id integer NOT NULL,
    city_id integer NOT NULL,
    institute_id integer NOT NULL,
    region_id integer NOT NULL,
    value character varying NOT NULL,
    variation_name character varying NOT NULL DEFAULT ''::character varying,
    aggregated_by period_enum NOT NULL,
    updated_at timestamp without time zone NOT NULL DEFAULT now(),
    CONSTRAINT indicator_values_pkey PRIMARY KEY (id),
    CONSTRAINT indicator_values_city_id_fkey FOREIGN KEY (city_id)
        REFERENCES city (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT indicator_values_indicator_id_fkey FOREIGN KEY (indicator_id)
        REFERENCES indicator (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT indicator_values_institute_id_fkey FOREIGN KEY (institute_id)
        REFERENCES institute (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT indicator_values_region_id_fkey FOREIGN KEY (region_id)
        REFERENCES region (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT indicator_values_user_id_fkey FOREIGN KEY (user_id)
        REFERENCES "user" (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION
);

create unique index ix_indicator_values_unique_by_city on indicator_values (indicator_id, valid_from, aggregated_by, user_id, variation_name)
where region_id is null;

create unique index ix_indicator_values_unique_by_region on indicator_values (indicator_id, valid_from, aggregated_by, user_id, variation_name, region_id)
where region_id is not null;

