use utf8;
package Iota::Schema::Result::UserRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::UserRole

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

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");

=head1 TABLE: C<user_role>

=cut

__PACKAGE__->table("user_role");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'user_role_id_seq'

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 role_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "user_role_id_seq",
  },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "role_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 role

Type: belongs_to

Related object: L<Iota::Schema::Result::Role>

=cut

__PACKAGE__->belongs_to(
  "role",
  "Iota::Schema::Result::Role",
  { id => "role_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "CASCADE," },
);

=head2 user

Type: belongs_to

Related object: L<Iota::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Iota::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 1, on_delete => "CASCADE,", on_update => "CASCADE," },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-05 18:12:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pCXer1cE04q9/TFOZzChAg

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
