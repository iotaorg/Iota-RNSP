use utf8;

package Iota::Schema::Result::NetworkUser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::NetworkUser

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::PassphraseColumn>

=back

=cut

__PACKAGE__->load_components( "InflateColumn::DateTime", "TimeStamp", "PassphraseColumn" );

=head1 TABLE: C<network_user>

=cut

__PACKAGE__->table("network_user");

=head1 ACCESSORS

=head2 network_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "network_id", { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "user_id",    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=item * L</network_id>

=back

=cut

__PACKAGE__->set_primary_key( "user_id", "network_id" );

=head1 RELATIONS

=head2 network

Type: belongs_to

Related object: L<Iota::Schema::Result::Network>

=cut

__PACKAGE__->belongs_to(
    "network",
    "Iota::Schema::Result::Network",
    { id            => "network_id" },
    { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 user

Type: belongs_to

Related object: L<Iota::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
    "user", "Iota::Schema::Result::User",
    { id            => "user_id" },
    { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-06-19 15:54:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vHdkv1fB75rnnz3Y2ua99A

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
