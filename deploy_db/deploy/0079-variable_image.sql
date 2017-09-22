-- Deploy iota:0079-variable_image to pg
-- requires: 0078-page.image

BEGIN;

alter table variable add column image_user_file_id int references user_file( id);
alter table variable add column display_order int;
alter table variable add column short_name varchar;

COMMIT;
