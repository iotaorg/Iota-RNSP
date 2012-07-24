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
    "city_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "api_key",
    { data_type => "text", is_nullable => 1 }
);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
    "city",
    "RNSP::PCS::Schema::Result::City",
    { id => "city_id" },
    {   is_deferrable => 1,
        join_type     => "LEFT",
        on_delete     => "CASCADE",
        on_update     => "CASCADE",
    },
);

__PACKAGE__->has_many(
    "user_roles",
    "RNSP::PCS::Schema::Result::UserRole",
    { "foreign.user_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);
__PACKAGE__->many_to_many( roles => user_roles => 'role' );

__PACKAGE__->load_components('PassphraseColumn');
__PACKAGE__->remove_column('password');
__PACKAGE__->add_column(
    password => {
        data_type        => "text",
        passphrase       => 'crypt',
        passphrase_class => 'BlowfishCrypt',
        passphrase_args  => {
            cost        => 8,
            salt_random => 1,
        },
        passphrase_check_method => 'check_password',
        is_nullable             => 0
    },
);

use List::MoreUtils qw(any all);

sub self_check     {1}
sub self_check_any {1}

sub check_any_role {
    my ( $self, @roles ) = @_;
    return any {
        my $role = $_->name;
        any { $_ eq $role } @roles;
    }
    $self->roles;
}

sub check_roles {
    my ( $self, @roles ) = @_;
    return all {
        my $role = $_->name;
        any { $_ eq $role } @roles;
    }
    $self->roles;
}
1;

