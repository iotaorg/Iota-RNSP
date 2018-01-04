copy (
    select source from public.variable_value where user_id in (
        select u.id from "user" u where u.id in (select user_id from network_user where network_id = 2) and u.city_id is not null
    ) UNION
    select source from public.region_variable_value where user_id in (
        select u.id from "user" u where u.id in (select user_id from network_user where network_id = 2) and u.city_id is not null
    ) group by 1 order by 1 )
to STDOUT CSV header;




copy (
    select observations from public.variable_value where user_id in (
        select u.id from "user" u where u.id in (select user_id from network_user where network_id = 2) and u.city_id is not null
    ) UNION
    select observations from public.region_variable_value where user_id in (
        select u.id from "user" u where u.id in (select user_id from network_user where network_id = 2) and u.city_id is not null
    ) group by 1 order by 1)
to STDOUT CSV header;

create temp table _rep (afrom varchar, bto varchar);

copy _rep from '/tmp/xxx.csv' csv header;
delete from _rep  where bto = '' or  bto is null;

update variable_value me set source = bto from (select id, bto from variable_value me join _rep o ON me.source = o.afrom) x where x.id = me.id;
update region_variable_value me set source = bto from (select id, bto from region_variable_value me join _rep o ON me.source = o.afrom) x where x.id = me.id;

update variable_value me set observations = bto from (select id, bto from variable_value me join _rep o ON me.observations = o.afrom) x where x.id = me.id;
update region_variable_value me set observations = bto from (select id, bto from region_variable_value me join _rep o ON me.observations = o.afrom) x where x.id = me.id;

-- reprocessar o banco depois disso
CATALYST_CONFIG=/src/iota.conf xDBIC_TRACE=1 perl -Ilib script/atualiza_valores_indicadores_regiao.pl
CATALYST_CONFIG=/src/iota.conf xDBIC_TRACE=1 perl -Ilib script/atualiza_valores_indicadores.pl
