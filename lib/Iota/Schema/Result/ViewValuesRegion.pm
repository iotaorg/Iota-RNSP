use utf8;

package Iota::Schema::Result::ViewValuesRegion;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

# For the time being this is necessary even for virtual views
__PACKAGE__->table('ViewValoresDistritos');

__PACKAGE__->add_columns(qw/variation_name valid_from num id/);

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(
    q[
    with tregions as (
     select id
        from region
        where depth_level = ? and city_id = (
            select city_id from region where id = ?
        )
    ), periods as  (
       select valid_from
       from indicator_value v
       join tregions x on x.id = v.region_id
       where v.city_id = (select city_id from "user" where id = ?) and v.indicator_id = ?
       group by 1
   )
   select
        variation_name,
        pp.valid_from,
        (CASE WHEN i.variable_type = 'str' THEN '1' ELSE value END)::numeric as num,
        r.id

    from region as r
    join tregions x on x.id=r.id
    CROSS join periods pp
    left join indicator_value v on r.id = v.region_id and v.city_id = (select city_id from "user" where id = ?) and v.indicator_id = ? and pp.valid_from = v.valid_from
    join indicator i on i.id = v.indicator_id

    order by num
]
);

1;
