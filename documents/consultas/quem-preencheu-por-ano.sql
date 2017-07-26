
CREATE OR REPLACE FUNCTION public.func_status_indicador_by_user_by_year_no_axis(
    abc integer,
     indicador_id integer,
    in_this_date date)
  RETURNS integer AS
$BODY$
declare
foo int;
BEGIN


select
  count(1) into foo
from indicator_value iv
where iv.user_id= abc and iv.indicator_id = indicador_id and iv.valid_from=in_this_date and iv.region_id is null;

RETURN foo;

END;
$BODY$
  LANGUAGE plpgsql STABLE
  COST 100;


drop table if exists _saida;
create temp table _saida as
select
    u.id as user_id,
    u.email as user_email,
    u.name as user_name,
    indicador.id as indicador_id,
    indicador.name as indicador_nome,

    func_status_indicador_by_user_by_year_no_axis(u.id, indicador.id, '2010-01-01'::date) as preenchido_2010,
    func_status_indicador_by_user_by_year_no_axis(u.id, indicador.id, '2016-01-01'::date) as preenchido_2016


from "user" u

cross join (
    select distinct x.id as id, x.name
        from indicator x
        where (
            x.visibility_level in ('public', 'network' )
        )
--        and id=3927
) indicador
where u.institute_id = 1
and u.city_id is not null;
--limit 10;

 copy (select indicador_id, indicador_nome , sum(preenchido_2010) as preenchido_2010, sum(preenchido_2016) as preenchido_2016 from  _saida group by 1,2 order by 2) to '/tmp/preenchidos.por.ano.csv' csv header;
COPY 260
