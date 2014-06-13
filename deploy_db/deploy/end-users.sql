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

create table end_user_indicators (
    id serial not null primary key,
    created_at timestamp not null default now(),

    end_user_id int not null,
    indicator_id int not null
);


alter table network add column is_virtual boolean not null default false;
-- update network set is_virtual = true where id=5;


COMMIT;
