-- Deploy iota:0085-disable_sort_direction to pg
-- requires: 0084-fix-rel

BEGIN;

alter table indicator add column is_sort_direction_meanless boolean not null default false;

-- rodar apenas na prod: primeira infancia
-- update indicator set is_sort_direction_meanless= true where id IN (3957, 3993);

COMMIT;
