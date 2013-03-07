DROP TABLE country;

CREATE TABLE country
(
  id serial NOT NULL,
  name_url text,
  name text,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  created_by integer NOT NULL,
  CONSTRAINT country_pkey PRIMARY KEY (id),
  CONSTRAINT country_name_uri_key UNIQUE (name_url)
)
WITH (
  OIDS=FALSE
);


-- Table: user_page

-- DROP TABLE user_page;

CREATE TABLE user_page
(
  id serial NOT NULL,
  user_id integer NOT NULL,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  pubished_at timestamp without time zone DEFAULT now(),
  title character varying NOT NULL,
  title_url character varying NOT NULL,
  content character varying NOT NULL,
  CONSTRAINT user_page_pkey PRIMARY KEY (id),
  CONSTRAINT user_page_user_id_fkey FOREIGN KEY (user_id)
      REFERENCES "user" (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE user_page
  OWNER TO postgres;
-- Table: user_menu

-- DROP TABLE user_menu;

CREATE TABLE user_menu
(
  id serial NOT NULL,
  user_id integer NOT NULL,
  page_id integer NOT NULL,
  title character varying NOT NULL,
  "position" integer NOT NULL DEFAULT 0,
  CONSTRAINT user_menu_pkey PRIMARY KEY (id),
  CONSTRAINT user_menu_page_id_fkey FOREIGN KEY (page_id)
      REFERENCES user_page (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT user_menu_user_id_fkey FOREIGN KEY (user_id)
      REFERENCES "user" (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE user_menu
  OWNER TO postgres;

