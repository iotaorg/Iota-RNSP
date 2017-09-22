-- Deploy iota:0077-bp_img_fields to pg
-- requires: 0076-DownloadData

BEGIN;

alter table user_best_pratice add column image_user_file_id int references user_file(id);
alter table user_best_pratice add column thumbnail_user_file_id int references user_file(id);


COMMIT;
