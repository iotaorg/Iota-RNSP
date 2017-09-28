-- Deploy iota:0083-page-type to pg
-- requires: 0082-fix-menu-equal-parent

BEGIN;

alter table user_page add column "type" varchar not null default 'html';

alter table user_page add column template_id int references "user_page" (id);
alter table user_page add check ( "type" in ('html', 'template', 'yaml')) ;


COMMIT;
