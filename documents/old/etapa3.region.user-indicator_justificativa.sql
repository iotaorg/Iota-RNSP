alter table user_indicator add column region_id int;

ALTER TABLE user_indicator
  ADD FOREIGN KEY (region_id) REFERENCES region (id) ON UPDATE NO ACTION ON DELETE NO ACTION;

