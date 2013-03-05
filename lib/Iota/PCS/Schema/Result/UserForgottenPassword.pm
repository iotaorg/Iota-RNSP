use utf8;
package Iota::PCS::Schema::Result::UserForgottenPassword;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::PCS::Schema::Result::UserForgottenPassword

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

=head1 TABLE: C<user_forgotten_passwords>

=cut

__PACKAGE__->table("user_forgotten_passwords");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'user_forgotten_passwords_id_seq'

=head2 id_user

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 secret_key

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 valid_until

  data_type: 'timestamp'
  default_value: (now() + '30 days'::interval)
  is_nullable: 1

=head2 reseted_at

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "user_forgotten_passwords_id_seq",
  },
  "id_user",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "secret_key",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "valid_until",
  {
    data_type     => "timestamp",
    default_value => \"(now() + '30 days'::interval)",
    is_nullable   => 1,
  },
  "reseted_at",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<user_forgotten_passwords_secret_key_key>

=over 4

=item * L</secret_key>

=back

=cut

__PACKAGE__->add_unique_constraint("user_forgotten_passwords_secret_key_key", ["secret_key"]);

=head1 RELATIONS

=head2 id_user

Type: belongs_to

Related object: L<Iota::PCS::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "id_user",
  "Iota::PCS::Schema::Result::User",
  { id => "id_user" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-11-23 09:26:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6SGOxNxIqP80sXcQhneyBg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
