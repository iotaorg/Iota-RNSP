alter table indicator_variables_variations_value add region_id int;

ALTER TABLE indicator_variables_variations_value
  ADD FOREIGN KEY (region_id) REFERENCES region (id) ON UPDATE NO ACTION ON DELETE NO ACTION;
