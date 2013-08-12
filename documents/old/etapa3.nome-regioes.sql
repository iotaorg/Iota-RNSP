
CREATE TABLE user_region
(
  id serial NOT NULL,
  depth_level smallint NOT NULL DEFAULT 2,
  user_id integer NOT NULL,
  region_classification_name character varying NOT NULL,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_region_pkey PRIMARY KEY (id),
  CONSTRAINT user_region_user_id_fkey FOREIGN KEY (user_id)
      REFERENCES "user" (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);