-- Deploy new_permissions_type
-- requires: variable_summarization

BEGIN;

-- 1. new type
create type tp_visibility_level_new as enum (
   'public',
    'private',
    'restrict',
    'network',
    'session'
);
-- 2. rename column(s) which uses our enum type
alter table indicator rename column visibility_level to _visibility_level;
-- 3. add new column of new type
alter table indicator add visibility_level tp_visibility_level_new not null default 'public';
-- 4. copy values to the new column
update indicator set visibility_level = _visibility_level::text::tp_visibility_level_new;
-- 5. remove old column and type
alter table indicator drop column _visibility_level;
drop type tp_visibility_level;

-- 6. rename to orignal
ALTER TYPE tp_visibility_level_new RENAME TO tp_visibility_level;


CREATE TABLE indicator_network_visibility
(
  id serial NOT NULL,
  indicator_id integer,
  network_id integer,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  created_by integer NOT NULL,
  CONSTRAINT indicator_network_visibility_pkey PRIMARY KEY (id),
  CONSTRAINT indicator_network_visibility_created_by_fkey FOREIGN KEY (created_by)
      REFERENCES "user" (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT indicator_network_visibility_indicator_id_fkey FOREIGN KEY (indicator_id)
      REFERENCES indicator (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT indicator_network_visibility_network_id_fkey FOREIGN KEY (network_id)
      REFERENCES "network" (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

-- why ??
update indicator
set visibility_user_id = null
where visibility_user_id is not null and visibility_level= 'public';

/*
-- MIGRATION PLANS FOR RNSP ONLY !

delete from network_user where user_id= 3 -- admin movimento
and network_id = 3; --  rede la


create table __tmp_migration_admin2net as
select (select network_id from network_user where user_id=visibility_user_id group by 1) as net_id, a.id as indicator_id
from indicator a
join "user" b on a.visibility_user_id=b.id
where b.city_id is null
and b.active;

insert into indicator_network_visibility ( network_id, indicator_id, created_by)
select net_id, indicator_id, 1
from __tmp_migration_admin2net;

update indicator set
visibility_level = 'network' where id in (
   select indicator_id from __tmp_migration_admin2net
);


drop table __tmp_migration_admin2net;
create table __tmp_migration_admin2net as
select
    (select network_id from network_user ab where ab.user_id= x.user_id group by 1) as net_id,
    a.id as indicator_id
from indicator a
join indicator_user_visibility x on x.indicator_id=a.id
join "user" b on x.user_id=b.id
where b.city_id is null
and b.active
and a.visibility_level='restrict';

delete from indicator_user_visibility where id in (

    select
        x.id
    from indicator a
    join indicator_user_visibility x on x.indicator_id=a.id
    join "user" b on x.user_id=b.id
    where b.city_id is null
    and b.active
    and a.visibility_level='restrict'

);

insert into indicator_network_visibility ( network_id, indicator_id, created_by)
select net_id, indicator_id, 1
from __tmp_migration_admin2net;

update indicator set
visibility_level = 'network' where id in (
   select indicator_id from __tmp_migration_admin2net
);

drop table __tmp_migration_admin2net;

update indicator set visibility_user_id = null where visibility_level = 'network' and visibility_user_id is not null;


*/

COMMIT;
