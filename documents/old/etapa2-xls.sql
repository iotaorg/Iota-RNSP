alter table variable_value add column file_id int;

create table "file" (
	id serial primary key,
	name varchar, 
	status_text varchar, 
	created_at timestamp without time zone DEFAULT now(),
        created_by integer NOT NULL
);

ALTER TABLE variable_value
ADD CONSTRAINT variable_value_file_id_fkey FOREIGN KEY (file_id)
REFERENCES file (id);
