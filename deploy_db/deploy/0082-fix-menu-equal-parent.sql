-- Deploy iota:0082-fix-menu-equal-parent to pg
-- requires: 0081-menu-cascade-delete

BEGIN;

update user_menu set menu_id=  null where menu_id= id;

COMMIT;
