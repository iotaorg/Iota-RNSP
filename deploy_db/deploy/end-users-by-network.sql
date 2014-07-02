-- Deploy end-users-by-network
-- requires: end-users

BEGIN;

alter table end_user_indicator add column network_id int not null;

ALTER TABLE end_user_indicator
  ADD FOREIGN KEY (network_id) REFERENCES network (id) ON UPDATE NO ACTION ON DELETE NO ACTION;


COMMIT;
