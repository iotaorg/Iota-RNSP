-- Deploy iota:0078-page.image to pg
-- requires: 0077-bp_img_fields

BEGIN;

alter table user_page add column image_user_file_id int references user_file(id);

COMMIT;
