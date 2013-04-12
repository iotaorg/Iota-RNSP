
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

drop table network ;
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

--alter table "user" add column network_id int;
alter table "user" add column created_at timestamp not null default now();



drop type tp_visibility_level cascade;
CREATE TYPE tp_visibility_level AS ENUM
   ('public',
    'private',
    'country',
    'restrict'
    );

alter table indicator add column visibility_level tp_visibility_level;

alter table indicator add visibility_user_id int ;
alter table indicator add visibility_country_id int ;

ALTER TABLE indicator
  ADD FOREIGN KEY (visibility_user_id) REFERENCES "user" (id) ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE indicator
  ADD FOREIGN KEY (visibility_country_id) REFERENCES country (id) ON UPDATE NO ACTION ON DELETE NO ACTION;

  drop table indicator_user_visibility ;
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


-- insert into role (name) values ('superadmin');


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



--alter table city add column state_id int;
--alter table city add column country_id int;

ALTER TABLE city
  ADD FOREIGN KEY (country_id) REFERENCES country (id) ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE city
  ADD FOREIGN KEY (state_id) REFERENCES state (id) ON UPDATE NO ACTION ON DELETE NO ACTION;

  -- Table: indicator_network_config

-- DROP TABLE indicator_network_config;

CREATE TABLE indicator_network_config
(
  indicator_id integer NOT NULL,
  network_id integer NOT NULL,
  unfolded_in_home boolean NOT NULL DEFAULT false,
  CONSTRAINT indicator_network_config_pkey PRIMARY KEY (indicator_id, network_id),
  CONSTRAINT indicator_network_config_fk_indicator_id FOREIGN KEY (indicator_id)
      REFERENCES indicator (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT indicator_network_config_fk_network_id FOREIGN KEY (network_id)
      REFERENCES network (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE indicator_network_config
  OWNER TO postgres;

-- Index: indicator_network_config_idx_indicator_id

-- DROP INDEX indicator_network_config_idx_indicator_id;

CREATE INDEX indicator_network_config_idx_indicator_id
  ON indicator_network_config
  USING btree
  (indicator_id);

-- Index: indicator_network_config_idx_network_id

--

DROP INDEX indicator_network_config_idx_network_id;

CREATE INDEX indicator_network_config_idx_network_id
  ON indicator_network_config
  USING btree
  (network_id);





INSERT INTO institute(
            id, name, short_name, description, created_at, users_can_edit_value,
            users_can_edit_groups, can_use_custom_css, can_use_custom_pages)
VALUES
(
    1, 'Prefeituras', 'gov', 'administrado pelas prefeituras', now(), true, false, false, false
),
(
    2, 'Movimentos', 'org', 'administrado pelos movimentos', now(), true, true, true, true
);

INSERT INTO country(
        id, name, name_url, created_by)
VALUES (1, 'Brasil','br',1);



insert into state (name_url, name, created_by, country_id, uf )
select lower(uf), uf, 1, 1, upper(uf) from city group by 1,2,3,4,5;

update city a set state_id = (select x.id from state x where a.uf = x.uf), country_id=1;



update "user" set name='superadmin', email='superadmin@email.com' where id=1;
delete from "user_role" where user_id = 1;

insert into "user_role"(user_Id, role_id) values (1, ( select id from "role" where name='superadmin' ));

update "user" set network_id = 1 where id in (select user_id from prefeitos);
update "user" set network_id = 2 where id in (select user_id from movimentos);


CREATE OR REPLACE VIEW city_current_user AS
 SELECT c.id AS city_id, u.id AS user_id
   FROM city c
   JOIN "user" u ON u.city_id = c.id;



ALTER TABLE user_file
   ALTER COLUMN created_at SET DEFAULT now() ;

update user_file set created_at=now() + (id ||'s')::interval;

ALTER TABLE user_file
ALTER COLUMN created_at SET NOT NULL;

update indicator set visibility_level ='public' where indicator_roles='_prefeitura,_movimento';

select count(1) from indicator where visibility_level is null; -- tem q ser 0











