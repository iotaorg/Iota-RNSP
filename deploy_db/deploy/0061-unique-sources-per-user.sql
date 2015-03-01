-- Deploy 0061-unique-sources-per-user
-- requires: 0060-campos-para-rdf

BEGIN;

delete from source where id not in (select max(id) from source group by user_id, lower(name));
create unique index on source (user_id, lower(name));

COMMIT;
