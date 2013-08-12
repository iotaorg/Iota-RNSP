-- Table: user_best_pratice

-- DROP TABLE user_best_pratice;

CREATE TABLE user_best_pratice
(
  id serial NOT NULL,
  user_id integer NOT NULL,
  axis_id integer NOT NULL,
  name text NOT NULL,
  description text,
  methodology text,
  goals text,
  schedule text,
  results text,
  institutions_involved text,
  contatcts text,
  sources text,
  tags text,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  name_url character varying NOT NULL,
  CONSTRAINT user_best_pratice_pkey PRIMARY KEY (id),
  CONSTRAINT user_best_pratice_user_id_fkey FOREIGN KEY (user_id)
      REFERENCES "user" (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);

CREATE TABLE user_best_pratice_axis
(
  id serial NOT NULL,
  axis_id integer NOT NULL,
  user_best_pratice_id integer NOT NULL,
  CONSTRAINT user_best_pratice_axis_pkey PRIMARY KEY (id),
  CONSTRAINT user_best_pratice_axis_axis_id_fkey FOREIGN KEY (axis_id)
      REFERENCES axis (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT user_best_pratice_axis_user_best_pratice_id_fkey FOREIGN KEY (user_best_pratice_id)
      REFERENCES user_best_pratice (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
