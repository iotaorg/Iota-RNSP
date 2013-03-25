
CREATE TABLE institute
(
  id serial NOT NULL,
  name text NOT NULL,
  short_name text NOT NULL,
  description text,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  users_can_edit_value boolean NOT NULL DEFAULT false,
  users_can_edit_groups boolean NOT NULL DEFAULT false,
  can_use_custom_css boolean NOT NULL DEFAULT false,
  can_use_custom_pages boolean NOT NULL DEFAULT false,
  CONSTRAINT institute_pkey PRIMARY KEY (id),
  CONSTRAINT institute_short_name_key UNIQUE (short_name)
)
WITH (
  OIDS=FALSE
);


CREATE TABLE network
(
  id serial NOT NULL,
  name text NOT NULL,
  name_url text NOT NULL,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  created_by integer NOT NULL,
  institute_id integer NOT NULL,
  domain_name character varying(100) NOT NULL,
  CONSTRAINT network_pkey PRIMARY KEY (id),
  CONSTRAINT network_fk_institute_id FOREIGN KEY (institute_id)
      REFERENCES institute (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT network_domain_name_key UNIQUE (domain_name),
  CONSTRAINT network_name_url_key UNIQUE (name_url)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE network
  OWNER TO postgres;

alter table "user" add column network_id int;
alter table "user" add column created_at timestamp not null default now();




CREATE TYPE tp_visibility_level AS ENUM
   ('public',
    'private',
    'contry',
    'restrict'
    );

alter table indicator add column visibility_level tp_visibility_level;


CREATE TABLE indicator_user_visibility
(
  id serial NOT NULL,
  indicator_id integer,
  user_id integer,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  created_by integer NOT NULL,
  CONSTRAINT indicator_user_visibility_pkey PRIMARY KEY (id),
  CONSTRAINT indicator_user_visibility_created_by_fkey FOREIGN KEY (created_by)
      REFERENCES "user" (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT indicator_user_visibility_indicator_id_fkey FOREIGN KEY (indicator_id)
      REFERENCES indicator (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT indicator_user_visibility_user_id_fkey FOREIGN KEY (user_id)
      REFERENCES "user" (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);


insert into role (name) values ('superadmin');


DROP TABLE country cascade;


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
DROP TABLE state cascade;

CREATE TABLE state
(
  id serial NOT NULL,
  name_url text,
  name text,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  created_by integer NOT NULL,
  country_id integer,
  uf text NOT NULL,
  CONSTRAINT state_pkey PRIMARY KEY (id),
  CONSTRAINT state_fk_country_id FOREIGN KEY (country_id)
      REFERENCES country (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT state_name_uri_key UNIQUE (name_url)
)
WITH (
  OIDS=FALSE
);


alter table city add column state_id int;
alter table city add column country_id int;

ALTER TABLE city
  ADD FOREIGN KEY (country_id) REFERENCES country (id) ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE city
  ADD FOREIGN KEY (state_id) REFERENCES state (id) ON UPDATE NO ACTION ON DELETE NO ACTION;
