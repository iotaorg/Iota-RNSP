-- Deploy variable-role
-- requires: permissions-for-regions

BEGIN;

alter table variable add column user_type varchar;

update variable m set user_type = (
    select x.name from "role" x
              join user_role b on b.user_id = m.user_id and x.id = b.role_id
              where role_id IN ( 0, 1, 2, 16 )
);

COMMIT;
