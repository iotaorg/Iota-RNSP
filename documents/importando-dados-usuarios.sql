-- em ambos os bancos de dados cria essa tabela
create table _city_vs_user_import (cityname varchar, user_id int);

-- popula a _city_vs_user_import com os nomes da cidade
-- no banco 'origem'
update _city_vs_user_import set user_id= fooobar from ( select a.cityname as foo, u.id as fooobar from _city_vs_user_import a left join city b on tira_acento(trim(a.cityname)) = tira_acento(trim(b.name)) left join "user" u on u.city_id = b.id and u.active and u.institute_id=1  ) x where cityname = foo;

alter table _city_vs_user_import alter column user_id set not null;

copy _city_vs_user_import to '/tmp/_city_vs_user_import.csv' csv ;



-- importa o _city_vs_user_import no banco destino
copy _city_vs_user_import from  '/tmp/_city_vs_user_import.csv' csv;

-- confere o de-para se não tem nenhum user faltando no banco destino
select a.*, u.name, u.id as user_id, u.email from _city_vs_user_import a left join city b on tira_acento(trim(a.cityname)) = tira_acento(trim(b.name)) left join "user" u on u.city_id = b.id and u.active and u.institute_id=1  order by 4;
-- ainda no banco de destino, configura o de-para dos users
alter table _city_vs_user_import add column local_user_id int;

update _city_vs_user_import set local_user_id = fooobar from ( select a.cityname as foo, u.id as fooobar from _city_vs_user_import a left join city b on tira_acento(trim(a.cityname)) = tira_acento(trim(b.name)) left join "user" u on u.city_id = b.id and u.active and u.institute_id=1  ) x where cityname = foo;

alter table _city_vs_user_import alter column local_user_id set not null;
alter table _city_vs_user_import alter column user_id set not null;
alter table _city_vs_user_import rename column user_id  to old_user_id;


------------- variaveis ---------------

-- depois de tratar os dadoss de quais variaveis vai puxar
copy (select local_variable_id,  arr_min(old_variable_id) as old_variable_id from really_import  where old_variable_id is not null) to '/tmp/de-para-var.csv' csv;

-- entra no banco antigo e roda

create table _var_vs_new (local_variable_id int, old_variable_id int);
copy _var_vs_new from '/tmp/de-para-var.csv' csv;

copy (  select * from _city_vs_user_import ci cross join _var_vs_new  vi  join variable_value vv on vv.user_id = ci.user_id and vv.variable_id=old_variable_id ) to '/tmp/export.csv' csv header;

-- na maquina nova:

create table _var_vs_new (local_variable_id int, old_variable_id int);

create table _import as select * from _city_vs_user_import ci cross join _var_vs_new  vi  join variable_value vv on vv.user_id = ci.old_user_id and vv.variable_id=old_variable_id limit 0;

copy _import (cityname         ,
old_user_id          ,
local_variable_id,
old_variable_id  ,
id               ,
value            ,
variable_id      ,
user_id          ,
created_at       ,
value_of_date    ,
valid_from       ,
valid_until      ,
observations     ,
source           ,
file_id          ,
cloned_from_user ) from  '/tmp/export.csv' csv header;

update _import i  set local_user_id =  a.local_user_id from _city_vs_user_import a where a.old_user_id = i.old_user_id;

insert into variable_value (id,value,variable_id,user_id,created_at,value_of_date,valid_from,valid_until,observations,source,file_id) select id,value,local_variable_id,local_user_id,created_at,value_of_date,valid_from,valid_until,observations,source,file_id from _import ;

-- agora sai e roda o script perl -Ilib script/atualiza_valores_indicadores.pl


