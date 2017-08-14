-- Deploy iota:0073-axis_aux3 to pg
-- requires: 0072-add_desc_eixo

BEGIN;

CREATE TABLE public.axis_dim3
(
  id serial NOT NULL,
  name text NOT NULL,
  description text,
  metaconfig text,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  created_by integer NOT NULL,
  CONSTRAINT axis_dim3_pkey PRIMARY KEY (id)
);

COMMIT;
