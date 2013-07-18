use utf8;

package Iota::Schema::Result::ViewIndicatorGoalRatio;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

# For the time being this is necessary even for virtual views
__PACKAGE__->table('ViewInstituteStats');

__PACKAGE__->add_columns(
    qw/
      id goal value ratio
      /
);

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

# WARNING: tomar cuidado no segundo bind, que precisa ser NULL ou = <int>

__PACKAGE__->result_source_instance->view_definition(
    q[
select
    i.id, i.goal, value,
    (((value::numeric / i.goal ) - 1) * 100)::int as ratio

from indicator_value x
inner join indicator i on i.id = x.indicator_id
where (x.valid_from, x.user_id, x.indicator_id) IN (
    select max(valid_from), user_id, indicator_id
    from indicator_value iv
    where user_id = ?
    AND region_id IS NULL
    group by 2,3
) and i.variable_type in ('num','int') and goal is not null
and i.goal != 0
]
);

1;
