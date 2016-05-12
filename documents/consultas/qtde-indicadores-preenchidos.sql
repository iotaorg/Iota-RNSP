
CREATE OR REPLACE FUNCTION func_status_indicador_by_user(
    abc integer,
    indicadores_id integer)
  RETURNS integer AS
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
    where
     i.id =indicadores_id
    GROUP BY i.id, i.axis_id, i.user_id,i.indicator_type,jm.COUNT
) x
where _count_any = var_count ;
RETURN foo;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100; ;


CREATE OR REPLACE FUNCTION func_status_indicador_by_user_justificado(
    abc integer,

    indicadores_id integer)
  RETURNS integer AS
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
    where   i.id  = indicadores_id
    GROUP BY i.id, i.axis_id, i.user_id,i.indicator_type,jm.COUNT
) x
where _count_any = var_count or justification_count > 0;
RETURN foo;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

copy (
select
    c.name as nome_cidade,
    c.uf as nome_uf,
    u.name as nome_usuario,

    u.email as email,

    c.id as city_id,

    u.id as user_id,
    x.id as indicator_id,
    x.name as indicator_name,
case when (func_status_indicador_by_user( u.id, x.id ) > 0) then 'sim' else 'nao' end as tem_indicador_preenchido,
case when (func_status_indicador_by_user_justificado( u.id, x.id ) > 0) then 'sim' else 'nao' end as tem_indicador_justificado_ou_preenchido



from "user" u
join city c on c.id=u.city_id
cross join indicator x
where
 u.institute_id = 1
 and u.active
and u.city_id is not null

and (
            (
                x.visibility_level='private' AND x.visibility_user_id = u.id
            )
            OR (
                x.visibility_level='network' AND x.id IN (
                    select indicator_id from indicator_network_visibility
                    where network_id = 1
                )
            )
        )

) to '/tmp/qtde-indicadores-preenchidos.csv' csv header;

