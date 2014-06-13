--
create temp table _stats_user_id as
select
a.id as user_id,
a.city_id
from "user"  a
--join network_user x1 on x1.user_id= a.id and x1.network_id=2
--left join network_user x2 on x2.user_id= a.id and x2.network_id!=2
join city c1 on c1.id = a.city_id
join country c2 on c2.id = c1.country_id
join state s1 on s1.id = c1.state_id
where /*x2.user_id is null
and */a.active = true;

create temp table _variables_filed1 as
select
user_id,
count(distinct variable_id) as distinct_variables,
count(distinct variable_id::text||valid_from::text) as distinct_years

from variable_value  x where user_id in (select user_id from _stats_user_id)
group by 1;


--- qtde regions and filled variables
copy (
select
    x.name as region_name,
    (select count(1) from region_variable_value m where m.region_id = x.id) as variables_filled
from region x where city_id in (select city_id from _stats_user_id) order by 2 desc )
to '/tmp/regioes.preenchidas.csv' csv header;




create temp table _fill_ind as
select

c.name as nome_cidade,
c.uf as nome_uf,
u.name as nome_usuario,
a.name as nome_eixo,
func_status_indicadores_by_user(u.id, a.id) as qtde_indicadores_preenchido,
func_status_indicadores_by_user_justificado(u.id, a.id) as qtde_indicadores_preenchido_ou_justificado,
(select count(1) from indicator x WHERE x.axis_id = a.id and (x.visibility_level='public' OR x.visibility_user_id
IN (select id from "user" where institute_id = 1 and city_Id is null and active and id != 767)
)) as total_indicadores_eixo,
c.id as city_id,
a.id as axis_id,
u.id as user_id

from "user" u
join city c on c.id=u.city_id
cross join axis a
where u.id In ( select user_id from _stats_user_id);



--------- saidas ---

copy(
select
c2.name as country_name,
s1.name as state_name,
c1.name as city_name,
a.name as user_name,
a.email as user_email,
a.id as user_id,
vf1.distinct_variables,
vf1.distinct_years,
(select count(distinct ts_created::date) from user_session x where x.user_id=a.id) as qtde_login_in_diff_days

from "user"  a
--join network_user x1 on x1.user_id= a.id and x1.network_id = 2
--left join network_user x2 on x2.user_id= a.id and x2.network_id != 2
join city c1 on c1.id = a.city_id
join country c2 on c2.id = c1.country_id
join state s1 on s1.id = c1.state_id
join _variables_filed1 vf1 on vf1.user_id = a.id
where /*x2.user_id is null
and */a.active = true
order by 1,2, 3, 4)
to '/tmp/variaveis.preenchidas.csv' csv header;




select *
from _fill_ind
where qtde_indicadores_preenchido > 0 or qtde_indicadores_preenchido_ou_justificado > 0;


copy (
select
 nome_cidade,
    nome_uf,
    nome_usuario,
 sum(qtde_indicadores_preenchido) as qtde_indicadores_preenchido,
 sum(qtde_indicadores_preenchido_ou_justificado) as qtde_indicadores_preenchido_ou_justificado
from _fill_ind
group by 1, 2,3
order by 4 desc
) to '/tmp/indicadores.preenchidos.csv' csv header;


create temp table _sum_regions as( select user_id, count(1) from region_variable_value group by 1);

-- obs: filtrado os movimentos
copy (
select i.name, u.name, c.pais,c.uf, c.name, count(distinct v.id) as values, rv.count as regions
from "user" u
join city c on c.id = u.city_id
join institute i on i.id = u.institute_id
left join variable_value v on v.user_Id=u.id
left join _sum_regions rv on rv.user_id=u.id
where u.active and i.id=2
group by 1,2,3,4,5,7 order by 6 desc) to '/tmp/valores.csv' csv header;


