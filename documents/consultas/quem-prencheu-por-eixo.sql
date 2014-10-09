


CREATE OR REPLACE FUNCTION func_status_indicadores_by_user(IN abc integer, in eixo int, in indicadores_ids int[])
  RETURNS int AS
$BODY$
declare
foo int;
BEGIN


select
  count(distinct id) into foo
from
(   SELECT

       i.id,


       (CASE WHEN i.indicator_type = 'varied' THEN
            COALESCE((SELECT MAX(x.casda) FROM (
             SELECT a.valid_from, COUNT(DISTINCT a.variation_name) AS casda
             FROM indicator_value a
             WHERE  a.indicator_id = i.id AND a.user_id = abc AND region_id IS NULL
             GROUP BY 1
            ) x)
            ,0)
       ELSE
          COUNT(DISTINCT iv_any.variation_name)
       END)::int AS _count_any,

       (greatest(1, (SELECT COUNT(1) FROM indicator_variations x WHERE x.indicator_id = i.id AND user_id IN (abc, i.user_id))))::int AS var_count,
       (jm.COUNT)::int AS justification_count
    FROM indicator i
    LEFT JOIN indicator_value iv_any ON iv_any.user_id = abc AND iv_any.indicator_id = i.id  AND iv_any.region_id IS NULL
    LEFT JOIN (SELECT indicator_id, COUNT(1) FROM user_indicator x WHERE x.user_id = abc AND justification_of_missing_field != '' GROUP BY 1) jm ON i.id = jm.indicator_id
    where i.axis_id= eixo
    and i.id IN (SELECT DISTINCT UNNEST(indicadores_ids))
    GROUP BY i.id, i.axis_id, i.user_id,i.indicator_type,jm.COUNT
) x
where _count_any = var_count ;
RETURN foo;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE;

  CREATE OR REPLACE FUNCTION func_status_indicadores_by_user_justificado(IN abc integer, in eixo int, in indicadores_ids int[])
  RETURNS int AS
$BODY$
declare
foo int;
BEGIN


select
  count(distinct id) into foo
from
(   SELECT

       i.id,


       (CASE WHEN i.indicator_type = 'varied' THEN
            COALESCE((SELECT MAX(x.casda) FROM (
             SELECT a.valid_from, COUNT(DISTINCT a.variation_name) AS casda
             FROM indicator_value a
             WHERE  a.indicator_id = i.id AND a.user_id = abc AND region_id IS NULL
             GROUP BY 1
            ) x)
            ,0)
       ELSE
          COUNT(DISTINCT iv_any.variation_name)
       END)::int AS _count_any,

       (greatest(1, (SELECT COUNT(1) FROM indicator_variations x WHERE x.indicator_id = i.id AND user_id IN (abc, i.user_id))))::int AS var_count,
       (jm.COUNT)::int AS justification_count
    FROM indicator i
    LEFT JOIN indicator_value iv_any ON iv_any.user_id = abc AND iv_any.indicator_id = i.id AND iv_any.region_id IS NULL
    LEFT JOIN (SELECT indicator_id, COUNT(1) FROM user_indicator x WHERE x.user_id = abc AND justification_of_missing_field != '' GROUP BY 1) jm ON i.id = jm.indicator_id
    where i.axis_id= eixo
    and i.id IN (SELECT DISTINCT UNNEST(indicadores_ids))
    GROUP BY i.id, i.axis_id, i.user_id,i.indicator_type,jm.COUNT
) x
where _count_any = var_count or justification_count > 0;
RETURN foo;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE;

create temp table _saida as
select

    c.name as nome_cidade,
    c.uf as nome_uf,
    u.name as nome_usuario,
    a.name as nome_eixo,

    u.email as email,
    case when  (select count(1) from user_file x where u.id=x.user_id and x.class_name='programa_metas')>=1 then 'sim' else 'nao' end as programa_de_metas,

    func_status_indicadores_by_user(u.id, a.id, array(

        select distinct x.id
        from indicator x
        WHERE x.axis_id = a.id
        and (
            x.visibility_level='public'
            OR (
                x.visibility_level='private' AND x.visibility_user_id IN (
                    select id from "user"
                    where institute_id = 1
                    and city_Id is not null
                    and active
                )
            )
            OR (
                x.visibility_level='network' AND x.id IN (
                    select indicator_id from indicator_network_visibility
                    where network_id = 1
                )
            )
        )

    )) as qtde_indicadores_preenchido,
    func_status_indicadores_by_user_justificado(u.id, a.id,
        array(

            select distinct x.id
            from indicator x
            WHERE x.axis_id = a.id
            and (
                x.visibility_level='public'
                OR (
                    x.visibility_level='private' AND x.visibility_user_id IN (
                        select id from "user"
                        where institute_id = 1
                        and city_Id is not null
                        and active
                    )
                )
                OR (
                    x.visibility_level='network' AND x.id IN (
                        select indicator_id from indicator_network_visibility
                        where network_id = 1
                    )
                )
            )

        )

    ) as qtde_indicadores_preenchido_ou_justificado,
    (
        select count(1)
        from indicator x
        WHERE x.axis_id = a.id
        and (
            x.visibility_level='public'
            OR (
                x.visibility_level='private' AND x.visibility_user_id IN (
                    select id from "user"
                    where institute_id = 1
                    and city_Id is not null
                    and active
                )
            )
            OR (
                x.visibility_level='network' AND x.id IN (
                    select indicator_id from indicator_network_visibility
                    where network_id = 1
                )
            )
        )
    ) as total_indicadores_eixo,
    c.id as city_id,
    a.id as axis_id,
    u.id as user_id

from "user" u
join city c on c.id=u.city_id
cross join axis a
where u.institute_id = 1
and u.city_id is not null;


copy _saida to '/tmp/status.indicadores.csv' CSV HEADER;

select id, name, email, cidade || ' - '||estado , (select count(1) from user_best_pratice x where x.user_id=me.id) as c from "user" me order by c desc;



---------




/* Relatório de Indicadores Novos */

drop table _saida;
create temp table _saida as
select

    c.name as nome_cidade,
    c.uf as nome_uf,
    u.name as nome_usuario,
    a.name as nome_eixo,

    u.email as email,

    (select count(distinct x.id)
        from indicator x
        WHERE x.axis_id = a.id
        and (

                 x.visibility_level='private' AND x.visibility_user_id IN (
                    u.id
                )
        )) as qtde_indicadores_privados,

    func_status_indicadores_by_user(u.id, a.id, array(

        select distinct x.id
        from indicator x
        WHERE x.axis_id = a.id
        and (

                 x.visibility_level='private' AND x.visibility_user_id IN (
                    u.id
                )
        )

    )) as qtde_indicadores_preenchido,
    func_status_indicadores_by_user_justificado(u.id, a.id,
        array(

            select distinct x.id
            from indicator x
            WHERE x.axis_id = a.id
            and (
                x.visibility_level='private' AND x.visibility_user_id IN (
                    u.id
                )
            )

        )

    ) as qtde_indicadores_preenchido_ou_justificado,

    c.id as city_id,
    a.id as axis_id,
    u.id as user_id

from "user" u
join city c on c.id=u.city_id
cross join axis a
where u.institute_id = 1
and u.city_id is not null
order by qtde_indicadores_privados desc;

select * from _saida;

copy _saida to '/tmp/indicadores.privados.csv' CSV HEADER;


-------------
/* Relatório de anos preenchidos (série histórica preenchida)
O que eu preciso saber é quantos anos foram preenchidos pela cidade de cada indicador. É possível?
**/



copy (

select
    c.name as nome_cidade,
    c.uf as nome_uf,
    u.name as nome_usuario,

    i.name as indicator_name,

    count(distinct iv.valid_from) as qtde_anos_distintos_preenchidos,

    c.id as city_id,
    u.id as user_id,
    i.id as indicator_id

from "user" u
join indicator_value iv on iv.user_id = u.id
join indicator i on iv.indicator_id = i.id
join city c on c.id=u.city_id
where u.institute_id = 1
and u.city_id is not null


group by nome_cidade,
    nome_uf,
    nome_usuario,

    indicator_name,
    c.id,
    u.id,
    i.id
) to '/tmp/anos.preenchidos.csv' csv header;


------------------------------
/*  O que eu preciso saber é se a cidade montou a regionalização e quais
    indicadores ela preencheu valores na regionalização. */


copy (

        select
            c.name as nome_cidade,
            c.uf as nome_uf,
            u.name as nome_usuario,

            array_agg(distinct i.name) as indicatores,
            array_agg(distinct r.name) as regioes,

            c.id as city_id,
            u.id as user_id

        from "user" u
        join indicator_value iv on iv.user_id = u.id and region_id is not null
        join indicator i on iv.indicator_id = i.id
        join region r on r.id = iv.region_id
        join city c on c.id=u.city_id
        where u.institute_id = 1
        and u.city_id is not null


        group by nome_cidade,
            nome_uf,
            nome_usuario,
            c.id,
            u.id,
            i.id

) to '/tmp/regioes.preenchidas.csv' csv header;
















