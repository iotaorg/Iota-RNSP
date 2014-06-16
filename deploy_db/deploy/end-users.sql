-- Deploy end-users
-- requires: appschema

BEGIN;

create table end_user (
    id serial not null primary key,
    created_at timestamp not null default now(),
    name varchar not null,
    email varchar not null,
    password varchar not null
);

drop table if exists end_user_indicators;

create table end_user_indicator (
    id serial not null primary key,
    created_at timestamp not null default now(),

    end_user_id int not null,

    -- qual indicador a pessoa que seguir.
    indicator_id int not null,

    -- boolean, se esta seguindo todas as cidades ou nao
    all_users boolean not null
);

create table end_user_indicator_user (
    id serial not null primary key,
    created_at timestamp not null default now(),

    -- assim sempre precisa ter a referencia
    end_user_indicator_id int not null,
    -- e assim pra facilitar o insert no log.
    indicator_id int not null,

    -- esse end-user
    end_user_id int not null,
    -- seguindo essa "cidade"
    user_id int not null
);


alter table network add column is_virtual boolean not null default false;
-- update network set is_virtual = true where id=5;

ALTER TABLE end_user_indicator_user
  ADD FOREIGN KEY (indicator_id) REFERENCES indicator (id) ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE end_user_indicator_user
  ADD FOREIGN KEY (end_user_indicator_id) REFERENCES end_user_indicator (id) ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE end_user_indicator_user
  ADD FOREIGN KEY (end_user_id) REFERENCES end_user (id) ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE end_user_indicator
  ADD FOREIGN KEY (end_user_id) REFERENCES end_user (id) ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE end_user_indicator
  ADD FOREIGN KEY (indicator_id) REFERENCES indicator (id) ON UPDATE NO ACTION ON DELETE NO ACTION;


COMMIT;
