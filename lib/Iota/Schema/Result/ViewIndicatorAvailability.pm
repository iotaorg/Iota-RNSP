use utf8;

package Iota::Schema::Result::ViewIndicatorAvailability;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

# For the time being this is necessary even for virtual views
__PACKAGE__->table('ViewIndicatorAvailability');

__PACKAGE__->add_columns(qw/region_1 region_2 region_3/);

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(
    q[
    SELECT
         CASE WHEN EXISTS (
            SELECT 1
            FROM indicator_value a
            WHERE a.indicator_id = ?
            AND region_id IS NOT NULL
            LIMIT 1
          ) THEN (
            SELECT 1
            FROM indicator_value a
            WHERE a.indicator_id = ?
            AND region_id IN ( SELECT id FROM region WHERE depth_level = 2 )
            LIMIT 1
          ) ELSE 0 END as region_2,

        CASE WHEN EXISTS (
            SELECT 1
            FROM indicator_value a
            WHERE a.indicator_id = ?
            AND region_id IS NOT NULL
            LIMIT 1
          ) THEN (
            SELECT 1
            FROM indicator_value a
            WHERE a.indicator_id = ?
            AND region_id IN ( SELECT id FROM region WHERE depth_level = 3 )
            LIMIT 1
          ) ELSE 0 END as region_3,

        CASE WHEN EXISTS (
            SELECT 1
            FROM indicator_value a
            WHERE a.indicator_id = ?
            AND region_id IS NULL
            LIMIT 1
          ) THEN 1 ELSE 0 END as region_1



]
);

1;
