alter table variable_value add column cloned_from_user int;
alter table region_variable_value add column cloned_from_user int;

ALTER TABLE region_variable_value
  ADD FOREIGN KEY (cloned_from_user) REFERENCES "user" (id) ON UPDATE NO ACTION ON DELETE NO ACTION;


ALTER TABLE variable_value
  ADD FOREIGN KEY (cloned_from_user) REFERENCES "user" (id) ON UPDATE NO ACTION ON DELETE NO ACTION;
