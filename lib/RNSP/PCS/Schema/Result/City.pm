
use utf8;

package RNSP::PCS::Schema::Result::City;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("city");

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => "user_id_seq",
    },
    "name",
    { data_type => "text", is_nullable => 0 },
    "uf",
    { data_type => "text", is_nullable => 0 },

    "type",
    {   data_type     => "enum",
        default_value => "prefeitura",
        extra         => {
            custom_type_name => "city_status_enum",
            list             => [ "prefeitura", "movimento" ],
        },
        is_nullable => 0,
    },

);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint( "user_city_type_key", [ "name", "uf", "type" ] );

__PACKAGE__->has_many(
    "users",
    "RNSP::PCS::Schema::Result::User",
    { "foreign.city_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

1;

