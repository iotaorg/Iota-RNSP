
use utf8;

package RNSP::PCS::Schema::Result::Indicator;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");


__PACKAGE__->table("indicator");

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => "indicator_id_seq",
    },
    "name",
    { data_type => "text", is_nullable => 0 },
    "formula",
    { data_type => "text", ids_nullable => 0 },

    "goal",
    { data_type => "numeric", is_nullable => 0 },

    "axis",
    { data_type => "text", is_nullable => 0 },

    "user_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },


    "created_at",
    {
        data_type     => "timestamp",
        default_value => \"current_timestamp",
        is_nullable   => 1,
        original      => { default_value => \"now()" },
    },


);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint( "indicator_cognomen_key", [ "name" ] );

__PACKAGE__->has_one(
    "owner",
    "RNSP::PCS::Schema::Result::User",
    { "foreign.id" => "self.user_id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

1;


