
CREATE TABLE indicator_value
(
    id serial NOT NULL,
    indicator_id integer NOT NULL,
    valid_from date NOT NULL,
    user_id integer NOT NULL,
    city_id integer ,
    institute_id integer NOT NULL,
    region_id integer ,
    value character varying NOT NULL,
    variation_name character varying NOT NULL DEFAULT ''::character varying,

    updated_at timestamp without time zone NOT NULL DEFAULT now(),

    sources varchar[],

    CONSTRAINT indicator_value_pkey PRIMARY KEY (id),
    CONSTRAINT indicator_value_city_id_fkey FOREIGN KEY (city_id)
        REFERENCES city (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT indicator_value_indicator_id_fkey FOREIGN KEY (indicator_id)
        REFERENCES indicator (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT indicator_value_institute_id_fkey FOREIGN KEY (institute_id)
        REFERENCES institute (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT indicator_value_region_id_fkey FOREIGN KEY (region_id)
        REFERENCES region (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT indicator_value_user_id_fkey FOREIGN KEY (user_id)
        REFERENCES "user" (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION
);

create unique index ix_indicator_value_unique_by_city on indicator_value (indicator_id, valid_from, user_id, variation_name)
where region_id is null;

create unique index ix_indicator_value_unique_by_region on indicator_value (indicator_id, valid_from, user_id, variation_name, region_id)
where region_id is not null;



CREATE TABLE indicator_variable
(
  id serial NOT NULL,
  indicator_id integer NOT NULL,
  variable_id integer NOT NULL,
  CONSTRAINT indicator_variable_pkey PRIMARY KEY (id),
  CONSTRAINT indicator_variable_indicator_id_fkey FOREIGN KEY (indicator_id)
      REFERENCES indicator (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT indicator_variable_variable_id_fkey FOREIGN KEY (variable_id)
      REFERENCES variable (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

alter table indicator add formula_human varchar ;