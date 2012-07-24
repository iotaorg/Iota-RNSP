
use utf8;

package RNSP::PCS::Schema::Result::Role;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("role");

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => "role_id_seq",
    },
    "name",
    { data_type => "text", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint( "role_name_key", ["name"] );

__PACKAGE__->has_many(
    "user_roles",
    "RNSP::PCS::Schema::Result::UserRole",
    { "foreign.role_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

1;
