select
    n.name as premio, u.name as prefeitura, u.id as user_id  ,
    i.name as indicator_name,
    c.name as cidade,
    r.name as regiao,
    iv.value as _valor_indicador,
    iv.valid_from as _data,
    iv.variation_name as _variacao,
    iv.values_used as _valores_variaveis
from  network_user nu
join "user" u on u.id=nu.useR_id
join city c on c.id = u.city_id
join network n on n.id = nu.network_id
join indicator_network_visibility inv on inv.network_id = n.id
join indicator i on i.id=inv.indicator_id
join indicator_value iv on iv.user_id = u.id and iv.indicator_id=i.id
left join region r on r.id=iv.region_id

where nu.network_id in ( select id from network where topic = true  ) and u.active and u.city_id is not null;

