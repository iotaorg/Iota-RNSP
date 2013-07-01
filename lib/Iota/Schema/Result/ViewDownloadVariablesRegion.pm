use utf8;

package Iota::Schema::Result::ViewDownloadVariablesRegion;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

# For the time being this is necessary even for virtual views
__PACKAGE__->table('ViewDownloadVariablesRegion');

__PACKAGE__->add_columns(
    qw/
      city_id city_name variable_id type cognomen period exp_source
      is_basic measurement_unit_name name valid_from value observations
      source user_id institute_id
      region_name region_id
      /
);

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(
    q[
    SELECT

        c.id as city_id,
        c.name as city_name,
        v.id as variable_id,
        v.type,
        v.cognomen,
        v.period::varchar,
        v.source as exp_source,
        v.is_basic,
        m.name as measurement_unit_name,
        v.name,
        vv.valid_from,
        vv.value,
        vv.observations,
        vv.source,
        vv.user_id,
        i.id as institute_id,
        r.name as region_name,
        r.id as region_id

    from region_variable_value vv
    join region r on vv.region_id = r.id
    join variable v on v.id = vv.variable_id
    left join measurement_unit m on m.id = v.measurement_unit_id
    join "user" u on u.id = vv.user_id
    join network_user nu on nu.user_id = u.id
    join network n on n.id = nu.network_id
    join institute i on i.id = n.institute_id
    join city c on c.id = u.city_id
    --where value is not null and value != ''
    where vv.region_id = ?
    union all
    SELECT

        c.id as city_id,
        c.name as city_name,
        -vvv.id as variable_id,
        v.type,
        v.name as cognomen,
        ix.period::varchar as period,
        null as exp_source,
        null as is_basic,
        null as measurement_unit_name,
        vvv.name || ': ' || v.name as name,
        vv.valid_from,
        vv.value,
        null as observations,
        null as source,
        vv.user_id,
        i.id as institute_id,
        r.name as region_name,
        r.id as region_id

    from indicator_variables_variations_value vv
    join region r on vv.region_id = r.id
    join indicator_variations vvv on vvv.id = indicator_variation_id
    join indicator_variables_variations v on v.id = vv.indicator_variables_variation_id
    join indicator ix on ix.id = vvv.indicator_id
    join "user" u on u.id = vv.user_id
    join network_user nu on nu.user_id = u.id
    join network n on n.id = nu.network_id
    join institute i on i.id = n.institute_id
    join city c on c.id = u.city_id
    where --value is not null and value != ''
    vv.region_id = ?

]
);

1;
