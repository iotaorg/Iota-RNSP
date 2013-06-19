CREATE TABLE network_user
(
  network_id integer NOT NULL,
  user_id integer NOT NULL,
  CONSTRAINT network_user_pkey PRIMARY KEY (user_id, network_id),
  CONSTRAINT network_user_network_id_fkey FOREIGN KEY (network_id)
      REFERENCES network (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT network_user_user_id_fkey FOREIGN KEY (user_id)
      REFERENCES "user" (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

alter table "user" rename network_id to _network_id  ;

alter table "user" add institute_id int;
ALTER TABLE "user"
  ADD FOREIGN KEY (institute_id) REFERENCES institute (id) ON UPDATE NO ACTION ON DELETE NO ACTION;

insert into network_user(user_id, network_id)
select id, _network_id from "user" where _network_id is not null;

update "user" a set institute_id = b.institute_id from network b where b.id = a._network_id;

alter table "user" drop column _network_id cascade;