use utf8;

package Iota::Schema::Result::ViewFatorDesigualdade;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

# For the time being this is necessary even for virtual views
__PACKAGE__->table('ViewFatorDesigualdade');

__PACKAGE__->add_columns(qw/valid_from max_valor min_valor fator max_nomes min_nomes/);

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(
    q[
    with tmp as (
        SELECT
            region_id, valid_from, value::numeric, variation_name, r.name as rname
        FROM indicator_value a
        join region r on r.id= a.region_id
        where (r.city_id, r.depth_level) in (
            select city_id, depth_level from region where id=?
        )
        and indicator_id = ?
        and user_id = ?
        AND value::numeric > 0
    )
    SELECT valid_from, max_valor, min_valor, max_valor/min_valor as fator,
        (select array_to_string(array_agg(DISTINCT rname), ', ') from tmp where "value" = max_valor) as max_nomes,
        (select array_to_string(array_agg(DISTINCT rname), ', ') from tmp where "value" = min_valor) as min_nomes
    FROM (
        select valid_from,
            max(value) as max_valor,
            min(value) as min_valor
        from tmp group by 1 ) zo
    ORDER BY valid_from
]
);

1;
