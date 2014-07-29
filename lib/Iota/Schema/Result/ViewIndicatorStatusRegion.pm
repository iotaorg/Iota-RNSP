use utf8;

package Iota::Schema::Result::ViewIndicatorStatusRegion;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

# For the time being this is necessary even for virtual views
__PACKAGE__->table('ViewIndicatorStatusRegion');

__PACKAGE__->add_columns(
    qw/
      id has_current has_data without_data justification_count
      /
);

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);
# bind order:
# [indicator ids]
# user_id
# region_id
# user_id
# user_id region_id
# user_id region_id
# user_id region_id
__PACKAGE__->result_source_instance->view_definition(
    q[
select
   r.id,
   r._count_last = r.var_count as has_current,
   r._count_any = r.var_count as has_data,
   r.justification_count,

   (NOT (r._count_last = r.var_count) AND NOT(r._count_any = r.var_count) ) as without_data

from (
    with
    indicators AS (
        select
            i.id,
            i.indicator_type,
            i.user_id,
            (select ultimo_periodo(i.period::period_enum)) as last_period
        from indicator i
        where i.id in (select * from UNNEST(?::int[]))
    )
    select

       i.id,
       count(distinct iv_last.variation_name) as _count_last,


       case when i.indicator_type = 'varied' then
            coalesce((select max(c) from (
             select a.valid_from, count(distinct a.variation_name) as c
             from indicator_value a
             where  a.indicator_id = i.id and user_id = ? and region_id = ?
             group by 1
            ) x),0)
       else
          count(distinct iv_any.variation_name)
       END as _count_any,

       greatest(1, (select count(1) from indicator_variations x WHERE x.indicator_id = i.id and user_id in (?, i.user_id))) as var_count,
       jm.count as justification_count

    from indicators i
    left join indicator_value iv_last on iv_last.user_id = ? and iv_last.indicator_id = i.id AND iv_last.valid_from = last_period AND iv_last.region_id = ?
    left join indicator_value iv_any on iv_any.user_id = ? and iv_any.indicator_id = i.id AND iv_any.region_id = ?
    LEFT JOIN (SELECT indicator_id, count(1) FROM user_indicator x WHERE x.user_id = ? and justification_of_missing_field != '' AND x.region_id= ? group by 1 ) jm on i.id = jm.indicator_id
    group by i.id,i.last_period, i.user_id,i.indicator_type,jm.count
) r



]
);

1;
