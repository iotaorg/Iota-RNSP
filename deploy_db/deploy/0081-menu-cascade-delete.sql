-- Deploy iota:0081-menu-cascade-delete to pg
-- requires: 0080-fix-source-insertion

BEGIN;

ALTER TABLE public.user_menu
  DROP CONSTRAINT user_menu_fk_menu_id;
ALTER TABLE public.user_menu
  ADD FOREIGN KEY (menu_id) REFERENCES public.user_menu (id) ON UPDATE CASCADE ON DELETE CASCADE;

COMMIT;
