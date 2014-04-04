-- Deploy region_config
-- requires: new_permissions_type

BEGIN;


CREATE TABLE region_config
(
    id serial NOT NULL primary key,

    institute_id integer NOT NULL,
    aggregate_only_if_full boolean NOT NULL,
    active_me_when_empty boolean NOT NULL,

    created_at timestamp not null default now(),


    CONSTRAINT region_config_institute_id_fkey FOREIGN KEY (institute_id)
        REFERENCES institute (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,

    CONSTRAINT region_config_institute_id_region_id_key UNIQUE (institute_id)
);

COMMENT ON COLUMN region_config.aggregate_only_if_full
    IS 'apenas faz as contas se as regioes abaixos estao com todas as variaveis preenchidas';

COMMENT ON COLUMN region_config.active_me_when_empty
    IS 'o dado da regiao acima ira se consolidar como ativo caso nao exista valores para as subs.';


insert into region_config(institute_id, aggregate_only_if_full, active_me_when_empty)
select id, true, true from institute ;


COMMIT;
