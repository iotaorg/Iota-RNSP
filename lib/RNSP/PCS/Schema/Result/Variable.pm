
use utf8;

package RNSP::PCS::Schema::Result::Variable;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");


__PACKAGE__->table("variable");

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => "variable_id_seq",
    },
    "name",
    { data_type => "text", is_nullable => 0 },
    "explanation",
    { data_type => "text", is_nullable => 0 },

    "cognomen",
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

    "type",
    {   data_type     => "enum",
        default_value => "str",
        extra         => {
            custom_type_name => "variable_type_enum",
            list             => [ "str", "int", "num" ],
        },
        is_nullable => 0,
    },

);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint( "variable_cognomen_key", [ "cognomen" ] );

__PACKAGE__->has_one(
    "owner",
    "RNSP::PCS::Schema::Result::User",
    { "foreign.id" => "self.user_id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

1;


