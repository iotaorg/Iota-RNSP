use utf8;
package RNSP::PCS::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

RNSP::PCS::Schema::Result::User

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

=head1 TABLE: C<user>

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'user_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 email

  data_type: 'text'
  is_nullable: 0

=head2 city_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 api_key

  data_type: 'text'
  is_nullable: 1

=head2 password

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "user_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "email",
  { data_type => "text", is_nullable => 0 },
  "city_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "api_key",
  { data_type => "text", is_nullable => 1 },
  "password",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<user_email_key>

=over 4

=item * L</email>

=back

=cut

__PACKAGE__->add_unique_constraint("user_email_key", ["email"]);

=head1 RELATIONS

=head2 city

Type: belongs_to

Related object: L<RNSP::PCS::Schema::Result::City>

=cut

__PACKAGE__->belongs_to(
  "city",
  "RNSP::PCS::Schema::Result::City",
  { id => "city_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 indicators

Type: has_many

Related object: L<RNSP::PCS::Schema::Result::Indicator>

=cut

__PACKAGE__->has_many(
  "indicators",
  "RNSP::PCS::Schema::Result::Indicator",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_forgotten_passwords

Type: has_many

Related object: L<RNSP::PCS::Schema::Result::UserForgottenPassword>

=cut

__PACKAGE__->has_many(
  "user_forgotten_passwords",
  "RNSP::PCS::Schema::Result::UserForgottenPassword",
  { "foreign.id_user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_roles

Type: has_many

Related object: L<RNSP::PCS::Schema::Result::UserRole>

=cut

__PACKAGE__->has_many(
  "user_roles",
  "RNSP::PCS::Schema::Result::UserRole",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 variable_values

Type: has_many

Related object: L<RNSP::PCS::Schema::Result::VariableValue>

=cut

__PACKAGE__->has_many(
  "variable_values",
  "RNSP::PCS::Schema::Result::VariableValue",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 variables

Type: has_many

Related object: L<RNSP::PCS::Schema::Result::Variable>

=cut

__PACKAGE__->has_many(
  "variables",
  "RNSP::PCS::Schema::Result::Variable",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07028 @ 2012-09-03 14:04:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:D5Npz4taNgeGoDtSEVAd5w

__PACKAGE__->has_many(
    "user_roles",
    "RNSP::PCS::Schema::Result::UserRole",
    { "foreign.user_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many( roles => user_roles => 'role' );

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

__PACKAGE__->might_have(
  "prefeito",
  "RNSP::PCS::Schema::Result::Prefeito",
  { "foreign.user_id" => "self.id", }
);

__PACKAGE__->might_have(
  "movimento",
  "RNSP::PCS::Schema::Result::Movimento",
  { "foreign.user_id" => "self.id" }
);


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
