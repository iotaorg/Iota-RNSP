

-- Table: user_page

-- DROP TABLE user_page;

CREATE TABLE user_page
(
  id serial NOT NULL,
  user_id integer NOT NULL,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  published_at timestamp without time zone DEFAULT now(),
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


-- DROP TABLE user_menu;
-- DROP TABLE user_menu;

CREATE TABLE user_menu
(
  id serial NOT NULL,
  user_id integer NOT NULL,
  page_id integer ,
  title text NOT NULL,
  "position" integer NOT NULL DEFAULT 0,
  menu_id integer,
  CONSTRAINT user_menu_pkey PRIMARY KEY (id),
  CONSTRAINT user_menu_fk_menu_id FOREIGN KEY (menu_id)
      REFERENCES user_menu (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT user_menu_fk_page_id FOREIGN KEY (page_id)
      REFERENCES user_page (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT user_menu_fk_user_id FOREIGN KEY (user_id)
      REFERENCES "user" (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);


-- Table: user_indicator_config

-- DROP TABLE user_indicator_config;

CREATE TABLE user_indicator_config
(
  id serial NOT NULL,
  user_id integer NOT NULL,
  indicator_id integer NOT NULL,
  technical_information text,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT user_indicator_config_pkey PRIMARY KEY (id),
  CONSTRAINT user_indicator_config_fk_indicator_id FOREIGN KEY (indicator_id)
      REFERENCES indicator (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT user_indicator_config_fk_user_id FOREIGN KEY (user_id)
      REFERENCES "user" (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT user_indicator_config_user_id_indicator_id_key UNIQUE (user_id, indicator_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE user_indicator_config
  OWNER TO postgres;

-- Index: user_indicator_config_idx_indicator_id

-- DROP INDEX user_indicator_config_idx_indicator_id;

CREATE INDEX user_indicator_config_idx_indicator_id
  ON user_indicator_config
  USING btree
  (indicator_id);

-- Index: user_indicator_config_idx_user_id

-- DROP INDEX user_indicator_config_idx_user_id;

CREATE INDEX user_indicator_config_idx_user_id
  ON user_indicator_config
  USING btree
  (user_id);

