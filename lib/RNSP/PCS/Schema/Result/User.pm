use utf8;

package RNSP::PCS::Schema::Result::User;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("user");

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => "user_id_seq",
    },
    "name",
    { data_type => "text", is_nullable => 0 },
    "email",
    { data_type => "text", is_nullable => 0 },
    "password",
    { data_type => "text", is_nullable => 0 },

);
__PACKAGE__->set_primary_key("id");

1;

