select a.id as user_id, a.name, c.uf, c.name as city_name, email, case when  (select count(1) from user_file x where a.id=x.user_id and class_name='programa_metas')>1 then 'sim' else 'nao' end
from "user"  a
join city c on c.id = a.city_id
where institute_id = 1
and a.city_id is not null
order by