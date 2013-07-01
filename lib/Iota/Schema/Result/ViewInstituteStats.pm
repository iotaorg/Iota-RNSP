use utf8;

package Iota::Schema::Result::ViewInstituteStats;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

# For the time being this is necessary even for virtual views
__PACKAGE__->table('ViewInstituteStats');

__PACKAGE__->add_columns(
    qw/
      name user_id city_name total_regions2 total_values2 total_regions2_perc
      total_regions3 total_values3 total_regions3_perc total_vars_last
      total_vars total_vars_last_perc
      /
);

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(
    q[
with var as (
    select count(1) as total_vars from variable
)
select
  u.name, u.id as user_id,
  c.name as city_name,
  urt2.total_regions2,
  urvt2.total_values2,

  urvt2.total_values2::numeric / urt2.total_regions2 *100 as total_regions2_perc,


  urt3.total_regions3,
  urvt3.total_values3,

  urvt3.total_values3::numeric / urt3.total_regions3 *100 as total_regions3_perc,

  uv.total_vars_last,
  (select total_vars from var) as total_vars,

  uv.total_vars_last::numeric / (select total_vars from var) *100 as total_vars_last_perc


from "user" u
join city c on c.id = u.city_id
left join (
   select city_id, count(1) as total_regions2 from region where depth_level = 2 group by 1
) urt2 on urt2.city_id = u.city_id

left join (
   select city_id, count(1) as total_regions3 from region where depth_level = 3 group by 1
) urt3 on urt3.city_id = u.city_id

left join (
   select user_id, count(distinct r.id) as total_values2
   from region r
   join region_variable_value uv on uv.region_id = r.id
   where r.depth_level = 2 group by 1
) urvt2 on urvt2.user_id = u.id

left join (
   select user_id, count(distinct r.id) as total_values3
   from region r
   join region_variable_value uv on uv.region_id = r.id
   where r.depth_level = 3 group by 1
) urvt3 on urvt3.user_id = u.id

left join (
   select x.user_id, count(distinct x.variable_id) as total_vars_last
   from variable_value x
   join variable y on x.variable_id = y.id
   where valid_from = ultimo_periodo(y.period)
   group by 1
) uv on uv.user_id = u.id

where u.institute_id = ?
and u.active
order by 2
]
);

1;
