-- Deploy region_config-fix
-- requires: region_config

BEGIN;


DROP TABLE region_config;

alter table institute add  aggregate_only_if_full boolean NOT NULL default false;
alter table institute add  active_me_when_empty boolean NOT NULL default false;

COMMENT ON COLUMN institute.aggregate_only_if_full
    IS 'apenas faz as contas se as regioes abaixos estao com todas as variaveis preenchidas';

COMMENT ON COLUMN institute.active_me_when_empty
    IS 'o dado da regiao acima ira se consolidar como ativo caso nao exista valores para as subs.';


COMMIT;
