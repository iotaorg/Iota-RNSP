
CREATE TABLE user_variable_config
(
  id serial NOT NULL,
  user_id integer NOT NULL,
  variable_id integer NOT NULL,
  display_in_home boolean not null default true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT user_variable_config_pkey PRIMARY KEY (id),
  CONSTRAINT user_variable_config_fk_variable_id FOREIGN KEY (variable_id)
      REFERENCES variable (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT user_variable_config_fk_user_id FOREIGN KEY (user_id)
      REFERENCES "user" (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT user_variable_config_user_id_variable_id_key UNIQUE (user_id, variable_id)
);


CREATE TABLE user_variable_region_config
(
  id serial NOT NULL,
  user_id integer NOT NULL,
  region_id integer NOT NULL,
  variable_id integer NOT NULL,
  display_in_home boolean NOT NULL DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT user_variable_region_config_pkey PRIMARY KEY (id),
  CONSTRAINT user_variable_region_config_region_id_fkey FOREIGN KEY (region_id)
      REFERENCES region (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT user_variable_region_config_user_id_fkey FOREIGN KEY (user_id)
      REFERENCES "user" (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT user_variable_region_config_variable_id_fkey FOREIGN KEY (variable_id)
      REFERENCES variable (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT user_variable_region_config_user_id_region_id_variable_id_key UNIQUE (user_id, region_id, variable_id)
);

alter table user_variable_config add column position int not null default 0;
alter table user_variable_region_config add column position int not null default 0;

insert into user_variable_config (
variable_id, display_in_home, user_id
)
 select id , true, ( select id from "user" where network_id=2 and city_id is null )
from variable
where cognomen = 'pop_total' or
cognomen = 'pop_rural' or
cognomen = 'pop_urbana' or
cognomen = 'pop_mulheres' or
cognomen = 'pop_homens' or
cognomen = 'densidade_demo' or
cognomen = 'area_municipio';

update user_variable_config set position=1 where variable_id = (select id from variable where cognomen = 'pop_total' ) and user_id =( select id from "user" where network_id=2 and city_id is null );
update user_variable_config set position=2 where variable_id = (select id from variable where cognomen = 'pop_rural' ) and user_id =( select id from "user" where network_id=2 and city_id is null );
update user_variable_config set position=3 where variable_id = (select id from variable where cognomen = 'pop_urbana' ) and user_id =( select id from "user" where network_id=2 and city_id is null );
update user_variable_config set position=4 where variable_id = (select id from variable where cognomen = 'pop_mulheres' ) and user_id =( select id from "user" where network_id=2 and city_id is null );
update user_variable_config set position=5 where variable_id = (select id from variable where cognomen = 'pop_homens' ) and user_id =( select id from "user" where network_id=2 and city_id is null );
update user_variable_config set position=6 where variable_id = (select id from variable where cognomen = 'densidade_demo' ) and user_id =( select id from "user" where network_id=2 and city_id is null );
update user_variable_config set position=7 where variable_id = (select id from variable where cognomen = 'area_municipio') and user_id =( select id from "user" where network_id=2 and city_id is null );



insert into user_variable_config (
variable_id, display_in_home, user_id
)
select id , true, ( select id from "user" where network_id=1 and city_id is null  order by 1 limit 1 )
from variable
where
cognomen ='prefeito' or
cognomen ='vice-prefeito' or
cognomen ='pop_total' or
cognomen ='pop_rural' or
cognomen ='pop_urbana' or
cognomen ='pop_mulheres' or
cognomen ='pop_homens' or
cognomen ='densidade_demo' or
cognomen ='area_municipio';


update user_variable_config set position=1 where variable_id = (select id from variable where cognomen = 'prefeito') and user_id =( select id from "user" where network_id=1 and city_id is null  order by 1 limit 1 );
update user_variable_config set position=2 where variable_id = (select id from variable where cognomen = 'vice-prefeito') and user_id =( select id from "user" where network_id=1 and city_id is null  order by 1 limit 1);
update user_variable_config set position=3 where variable_id = (select id from variable where cognomen = 'pop_total') and user_id =( select id from "user" where network_id=1 and city_id is null  order by 1 limit 1);
update user_variable_config set position=4 where variable_id = (select id from variable where cognomen = 'pop_rural') and user_id =( select id from "user" where network_id=1 and city_id is null  order by 1 limit 1);
update user_variable_config set position=5 where variable_id = (select id from variable where cognomen = 'pop_urbana') and user_id =( select id from "user" where network_id=1 and city_id is null  order by 1 limit 1);
update user_variable_config set position=6 where variable_id = (select id from variable where cognomen = 'pop_mulheres') and user_id =( select id from "user" where network_id=1 and city_id is null  order by 1 limit 1);
update user_variable_config set position=7 where variable_id = (select id from variable where cognomen = 'pop_homens') and user_id =( select id from "user" where network_id=1 and city_id is null  order by 1 limit 1);
update user_variable_config set position=8 where variable_id = (select id from variable where cognomen = 'densidade_demo') and user_id =( select id from "user" where network_id=1 and city_id is null  order by 1 limit 1);
update user_variable_config set position=9 where variable_id = (select id from variable where cognomen = 'area_municipio') and user_id =( select id from "user" where network_id=1 and city_id is null  order by 1 limit 1);

