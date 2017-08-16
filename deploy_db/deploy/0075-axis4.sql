-- Deploy iota:0075-axis4 to pg
-- requires: 0074-axis_3

BEGIN;

alter table axis_dim3 drop column metaconfig;

CREATE TABLE public.axis_dim4
(
  id serial NOT NULL ,
  name text NOT NULL,
  description text,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  created_by integer NOT NULL,
  PRIMARY KEY (id)
);
alter table indicator add column axis_dim4_id int references axis_dim4(id);

COMMIT;
