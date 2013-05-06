
CREATE TABLE user_variable_config
(
  id serial NOT NULL,
  user_id integer NOT NULL,
  variable_id integer NOT NULL,
  display_in_home boolean not null default true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT user_variable_config_pkey PRIMARY KEY (id),
  CONSTRAINT user_variable_config_fk_variable_id FOREIGN KEY (variable_id)
      REFERENCES variable (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT user_variable_config_fk_user_id FOREIGN KEY (user_id)
      REFERENCES "user" (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT user_variable_config_user_id_variable_id_key UNIQUE (user_id, variable_id)
);


CREATE TABLE user_variable_region_config
(
  id serial NOT NULL,
  user_id integer NOT NULL,
  region_id integer NOT NULL,
  variable_id integer NOT NULL,
  display_in_home boolean NOT NULL DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT user_variable_region_config_pkey PRIMARY KEY (id),
  CONSTRAINT user_variable_region_config_region_id_fkey FOREIGN KEY (region_id)
      REFERENCES region (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT user_variable_region_config_user_id_fkey FOREIGN KEY (user_id)
      REFERENCES "user" (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT user_variable_region_config_variable_id_fkey FOREIGN KEY (variable_id)
      REFERENCES variable (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT user_variable_region_config_user_id_region_id_variable_id_key UNIQUE (user_id, region_id, variable_id)
);