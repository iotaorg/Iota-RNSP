use utf8;

package Iota::Schema::Result::ViewIndicatorAvailabilityWithID;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

# For the time being this is necessary even for virtual views
__PACKAGE__->table('ViewIndicatorAvailabilityWithID');

__PACKAGE__->add_columns(qw/indicator_id/);

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(
    q[
        SELECT a.indicator_id
        FROM indicator_value a
        WHERE region_id IN ( SELECT r.id FROM region r WHERE r.depth_level = ? AND r.city_id = ? )
        AND a.user_id = ? AND  a.valid_from IN (SELECT DISTINCT UNNEST( ?::date[] ))
        GROUP BY 1

]
);

1;
