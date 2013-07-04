use utf8;

package Iota::Schema::Result::ViewValuesRegion;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

# For the time being this is necessary even for virtual views
__PACKAGE__->table('ViewValoresDistritos');

__PACKAGE__->add_columns(qw/variation_name valid_from name num polygon_path name_url/);

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(
    q[
    with periods as  (
       select valid_from
       from indicator_value v
       where v.city_id = (select city_id from "user" where id = ?) and v.indicator_id = ?
       group by 1
   )
   select
        coalesce(variation_name, '') as variation_name,
        pp.valid_from,
        r.name,
        value::numeric as num,
        polygon_path,
        r.name_url

    from region as r
    CROSS join periods pp
    left join indicator_value v on r.id = v.region_id and v.city_id = (select city_id from "user" where id = ?) and v.indicator_id = ? and pp.valid_from = v.valid_from
    where
     r.id in (
        select id
        from region
        where depth_level = ? and city_id = (
            select city_id from region where id = ?
        )
    )
    order by num
]
);

1;
