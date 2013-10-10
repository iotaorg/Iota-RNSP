-- Revert variable-role

BEGIN;

alter table variable drop column user_type  ;


COMMIT;
