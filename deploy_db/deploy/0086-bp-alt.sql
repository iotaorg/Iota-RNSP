-- Deploy iota:0086-bp-alt to pg
-- requires: 0085-disable_sort_direction

BEGIN;
alter table user_best_pratice add column image_caption varchar;
COMMIT;
