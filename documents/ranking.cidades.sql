
with rs as (
    select
        variation_name,
        r.name,
        value::numeric as rvalue

    from indicator_value v
    join region r on r.id = v.region_id
    where
    v.indicator_id = 5
    and v.city_id = 1
    and v.region_id in (
        select id
        from region
        where (depth_level, city_id) = (
            select depth_level, city_id from region where id = 5
        )
    )

    order by rvalue
)
select
 (select sum(x.rvalue) from rs x)as max,
 variation_name,
 name,
 rvalue
from rs
