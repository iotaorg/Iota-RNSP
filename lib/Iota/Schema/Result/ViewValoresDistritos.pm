use utf8;

package Iota::Schema::Result::ViewValoresDistritos;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

# For the time being this is necessary even for virtual views
__PACKAGE__->table('ViewValoresDistritos');

__PACKAGE__->add_columns(qw/variation_name valid_from name num polygon_path/);

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(q[
    select
        variation_name,
        v.valid_from,
        r.name,
        value::numeric as num,
        polygon_path

    from indicator_value v
    join region r on r.id = v.region_id
    where
    v.indicator_id = ?
    and v.city_id = (select city_id from "user" where id = ?)
    and v.region_id in (
        select id
        from region
        where depth_level = 3 and city_id = (
            select city_id from region where id = ?
        )
    )

    order by num

]);

1;