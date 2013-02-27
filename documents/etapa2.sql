CREATE TABLE network
(
  id serial NOT NULL,
  name text NOT NULL,
  name_url text NOT NULL,
  users_can_edit_value boolean not null default false,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  created_by integer NOT NULL,
  CONSTRAINT network_pkey PRIMARY KEY (id),
  CONSTRAINT network_name_url_key UNIQUE (name_url)
)
WITH (
  OIDS=FALSE
);


alter table "user" add column network_id int;


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


create table country (
  id serial NOT NULL primary key,
  name_uri varchar unique,
  name varchar ,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  created_by integer NOT NULL
);



create table state (
  id serial NOT NULL primary key,
  name_uri varchar unique,
  name varchar ,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  created_by integer NOT NULL
);


alter table city add column state_id int;
alter table city add column country_id int;

ALTER TABLE city
  ADD FOREIGN KEY (country_id) REFERENCES country (id) ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE city
  ADD FOREIGN KEY (state_id) REFERENCES state (id) ON UPDATE NO ACTION ON DELETE NO ACTION;
