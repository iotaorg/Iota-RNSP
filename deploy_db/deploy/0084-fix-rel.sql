-- Deploy iota:0084-fix-rel to pg
-- requires: 0083-page-type

BEGIN;

ALTER TABLE public.indicator DROP CONSTRAINT indicator_axis_dim3_id_fkey;

ALTER TABLE public.indicator
  ADD CONSTRAINT indicator_axis_dim3_id_fkey FOREIGN KEY (axis_dim3_id)
      REFERENCES public.axis_dim3 (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION;


COMMIT;
