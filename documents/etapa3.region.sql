drop table if exists region cascade;

CREATE TABLE region
(
    id serial NOT NULL,
    name character varying NOT NULL,
    name_url character varying NOT NULL,
    description character varying ,
    city_id integer NOT NULL,
    upper_region integer,
    depth_level smallint NOT NULL DEFAULT 2,
    created_at timestamp without time zone NOT NULL DEFAULT now(),
    created_by integer NOT NULL,
    CONSTRAINT region_pkey PRIMARY KEY (id),
    CONSTRAINT region_city_id_fkey FOREIGN KEY (city_id)
        REFERENCES city (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT region_created_by_fkey FOREIGN KEY (created_by)
        REFERENCES "user" (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT region_upper_region_fkey FOREIGN KEY (upper_region)
        REFERENCES region (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT region_depth_level_check CHECK (depth_level = ANY (ARRAY[2, 3]))
);


DROP TABLE if exists region_variable_value;

CREATE TABLE region_variable_value
(
    id serial NOT NULL,
    region_id integer NOT NULL,
    variable_id integer NOT NULL,
    value character varying,
    user_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    value_of_date timestamp without time zone,
    valid_from date,
    valid_until date,
    observations character varying,
    source character varying,
    file_id integer,
    CONSTRAINT region_variable_value_pkey PRIMARY KEY (id),
    CONSTRAINT region_variable_value_region_id_fkey FOREIGN KEY (region_id)
        REFERENCES region (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT region_variable_value_user_id_fkey FOREIGN KEY (user_id)
        REFERENCES "user" (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT region_variable_value_variable_id_fkey FOREIGN KEY (variable_id)
        REFERENCES variable (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT region_variable_value_region_id_variable_id_user_id_valid_f_key UNIQUE (region_id, variable_id, user_id, valid_from)
);







