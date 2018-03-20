CREATE OR REPLACE FUNCTION public.func_status_indicador_by_user_depth_1 (
    abc integer,
     indicador_id integer)
  RETURNS integer AS
$BODY$
declare
foo int;
BEGIN


select
  count(1) into foo
from indicator_value iv
where iv.user_id = abc and iv.indicator_id = indicador_id and iv.region_id is null;

RETURN foo;

END;
$BODY$
  LANGUAGE plpgsql STABLE
  COST 100;


CREATE OR REPLACE FUNCTION public.func_status_indicador_by_user_depth_N (
    abc integer,
     indicador_id integer, DEPTH integer)
  RETURNS integer AS
$BODY$
declare
foo int;
BEGIN
select
  count(1) into foo
from indicator_value iv
where iv.user_id = abc and iv.indicator_id = indicador_id and iv.region_id in ( select id from region where depth_level = DEPTH  and city_id= (select city_id from "user" u where u.id = abc));
RETURN foo;
END;
$BODY$
  LANGUAGE plpgsql STABLE
  COST 100;


drop table if exists _saida;
create temp table _saida as
select
    c.name as nome_cidade,
    c.uf as nome_uf,
    u.name as nome_usuario,
    u.id as user_id,
    u.name as user_name,

    indicador.id as indicador_id,
    indicador.name as indicador_nome,

    func_status_indicador_by_user_depth_1(u.id, indicador.id) > 0 as depth_level_1,
    func_status_indicador_by_user_depth_N(u.id, indicador.id, 2) > 0 as depth_level_2,
    func_status_indicador_by_user_depth_N(u.id, indicador.id, 3) > 0 as depth_level_3

from "user" u
join city c on c.id=u.city_id

cross join (
        select distinct x.id as id, x.name
        from indicator x
        where (
                x.visibility_level='public'
                OR (
                    x.visibility_level='private' AND x.visibility_user_id = 11
                )
                OR (
                    x.visibility_level='network' AND x.id IN (
                        select indicator_id from indicator_network_visibility
                        where network_id  in ( select id from network  where domain_name = 'www.redesocialdecidades.org.br' )
                    )
                )

        )
) indicador
where u.id = 11;
--limit 10;

copy _saida to '/tmp/indicadores-preenchidos-por-nivel.csv' csv header;