-- Deploy iota:0074-axis_3 to pg
-- requires: 0073-axis_aux3

BEGIN;

alter table indicator add column axis_dim3_id int references axis_dim1 (id);

alter table user_best_pratice add column axis_dim1_id int references axis_dim1 (id);
alter table user_best_pratice add column axis_dim2_id int references axis_dim2 (id);
alter table user_best_pratice add column axis_dim3_id int references axis_dim3 (id);

alter table user_best_pratice add column reference_city varchar;


COMMIT;
