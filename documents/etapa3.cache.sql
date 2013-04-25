
CREATE TABLE indicator_values
(
  id integer NOT NULL,
  indicator_id integer NOT NULL,
  valid_from date NOT NULL,
  user_id integer NOT NULL,
  city_id integer NOT NULL,
  state_id integer NOT NULL,
  country_id integer NOT NULL,
  institute_id integer NOT NULL,
  value character varying NOT NULL,
  variation_name character varying NOT NULL DEFAULT ''::character varying,
  aggregated_by period_enum NOT NULL,
  updated_at timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT indicator_values_pkey PRIMARY KEY (id),
  CONSTRAINT indicator_values_city_id_fkey FOREIGN KEY (city_id)
      REFERENCES city (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT indicator_values_country_id_fkey FOREIGN KEY (country_id)
      REFERENCES country (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT indicator_values_indicator_id_fkey FOREIGN KEY (indicator_id)
      REFERENCES indicator (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT indicator_values_institute_id_fkey FOREIGN KEY (institute_id)
      REFERENCES institute (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT indicator_values_state_id_fkey FOREIGN KEY (state_id)
      REFERENCES state (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT indicator_values_user_id_fkey FOREIGN KEY (user_id)
      REFERENCES "user" (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT indicator_values_indicator_id_valid_from_aggregated_by_user_key UNIQUE (indicator_id, valid_from, aggregated_by, user_id, variation_name)
);

