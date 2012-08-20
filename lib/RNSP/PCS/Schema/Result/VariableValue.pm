
use utf8;

package RNSP::PCS::Schema::Result::VariableValue;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");


__PACKAGE__->table("variable_value");

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => "variable_value_id_seq",
    },
    "value",
    { data_type => "text", is_nullable => 0 },

    "variable_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },

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

__PACKAGE__->belongs_to(
    "owner",
    "RNSP::PCS::Schema::Result::User",
    { "foreign.id" => "self.user_id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->add_unique_constraint( "var_user_key", [ "variable_id", "user_id" ] );


__PACKAGE__->belongs_to(
    "variable",
    "RNSP::PCS::Schema::Result::Variable",
    { "foreign.id" => "self.variable_id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

1;


