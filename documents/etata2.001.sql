

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


-- DROP TABLE user_menu;
-- DROP TABLE user_menu;

CREATE TABLE user_menu
(
  id serial NOT NULL,
  user_id integer NOT NULL,
  page_id integer NOT NULL,
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

