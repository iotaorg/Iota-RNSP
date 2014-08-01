use utf8;

package Iota::Schema::Result::ViewValuesByPeriod;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

# For the time being this is necessary even for virtual views
__PACKAGE__->table('ViewValuesByPeriod');

__PACKAGE__->add_columns(qw/variable_id variable_name valid_from/);

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(
    q[
    with vperiods as (
        select valid_from, variable_id, user_id
        from variable_value x
        where x.variable_id in (select * from UNNEST(?::int[]))
        and user_id = ?
        group by 1,2,3
    )
    select
        p.variable_id,
        v.name as variable_name,
        x.valid_from
    from variable v
    join vperiods p on p.variable_id = v.id
    left join variable_value x on x.valid_from = p.valid_from and x.user_id=p.user_id and x.variable_id=p.variable_id
    where x.value != ''
]
);

1;
