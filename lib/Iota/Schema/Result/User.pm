use utf8;
package Iota::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::User

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

=head2 nome_responsavel_cadastro

  data_type: 'text'
  is_nullable: 1

=head2 estado

  data_type: 'text'
  is_nullable: 1

=head2 telefone

  data_type: 'text'
  is_nullable: 1

=head2 email_contato

  data_type: 'text'
  is_nullable: 1

=head2 telefone_contato

  data_type: 'text'
  is_nullable: 1

=head2 cidade

  data_type: 'text'
  is_nullable: 1

=head2 bairro

  data_type: 'text'
  is_nullable: 1

=head2 cep

  data_type: 'text'
  is_nullable: 1

=head2 endereco

  data_type: 'text'
  is_nullable: 1

=head2 city_summary

  data_type: 'text'
  is_nullable: 1

=head2 active

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 network_id

  data_type: 'integer'
  is_foreign_key: 1
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
  "nome_responsavel_cadastro",
  { data_type => "text", is_nullable => 1 },
  "estado",
  { data_type => "text", is_nullable => 1 },
  "telefone",
  { data_type => "text", is_nullable => 1 },
  "email_contato",
  { data_type => "text", is_nullable => 1 },
  "telefone_contato",
  { data_type => "text", is_nullable => 1 },
  "cidade",
  { data_type => "text", is_nullable => 1 },
  "bairro",
  { data_type => "text", is_nullable => 1 },
  "cep",
  { data_type => "text", is_nullable => 1 },
  "endereco",
  { data_type => "text", is_nullable => 1 },
  "city_summary",
  { data_type => "text", is_nullable => 1 },
  "active",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "network_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
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

=head2 actions_logs

Type: has_many

Related object: L<Iota::Schema::Result::ActionsLog>

=cut

__PACKAGE__->has_many(
  "actions_logs",
  "Iota::Schema::Result::ActionsLog",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 city

Type: belongs_to

Related object: L<Iota::Schema::Result::City>

=cut

__PACKAGE__->belongs_to(
  "city",
  "Iota::Schema::Result::City",
  { id => "city_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 indicator_user_visibilities_created_by

Type: has_many

Related object: L<Iota::Schema::Result::IndicatorUserVisibility>

=cut

__PACKAGE__->has_many(
  "indicator_user_visibilities_created_by",
  "Iota::Schema::Result::IndicatorUserVisibility",
  { "foreign.created_by" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicator_user_visibility_users

Type: has_many

Related object: L<Iota::Schema::Result::IndicatorUserVisibility>

=cut

__PACKAGE__->has_many(
  "indicator_user_visibility_users",
  "Iota::Schema::Result::IndicatorUserVisibility",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicator_variations

Type: has_many

Related object: L<Iota::Schema::Result::IndicatorVariation>

=cut

__PACKAGE__->has_many(
  "indicator_variations",
  "Iota::Schema::Result::IndicatorVariation",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicators

Type: has_many

Related object: L<Iota::Schema::Result::Indicator>

=cut

__PACKAGE__->has_many(
  "indicators",
  "Iota::Schema::Result::Indicator",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 network

Type: belongs_to

Related object: L<Iota::Schema::Result::Network>

=cut

__PACKAGE__->belongs_to(
  "network",
  "Iota::Schema::Result::Network",
  { id => "network_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 sources

Type: has_many

Related object: L<Iota::Schema::Result::Source>

=cut

__PACKAGE__->has_many(
  "sources",
  "Iota::Schema::Result::Source",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_files

Type: has_many

Related object: L<Iota::Schema::Result::UserFile>

=cut

__PACKAGE__->has_many(
  "user_files",
  "Iota::Schema::Result::UserFile",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_forgotten_passwords

Type: has_many

Related object: L<Iota::Schema::Result::UserForgottenPassword>

=cut

__PACKAGE__->has_many(
  "user_forgotten_passwords",
  "Iota::Schema::Result::UserForgottenPassword",
  { "foreign.id_user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_indicator_axes

Type: has_many

Related object: L<Iota::Schema::Result::UserIndicatorAxis>

=cut

__PACKAGE__->has_many(
  "user_indicator_axes",
  "Iota::Schema::Result::UserIndicatorAxis",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_indicator_configs

Type: has_many

Related object: L<Iota::Schema::Result::UserIndicatorConfig>

=cut

__PACKAGE__->has_many(
  "user_indicator_configs",
  "Iota::Schema::Result::UserIndicatorConfig",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_indicators

Type: has_many

Related object: L<Iota::Schema::Result::UserIndicator>

=cut

__PACKAGE__->has_many(
  "user_indicators",
  "Iota::Schema::Result::UserIndicator",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_roles

Type: has_many

Related object: L<Iota::Schema::Result::UserRole>

=cut

__PACKAGE__->has_many(
  "user_roles",
  "Iota::Schema::Result::UserRole",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_sessions

Type: has_many

Related object: L<Iota::Schema::Result::UserSession>

=cut

__PACKAGE__->has_many(
  "user_sessions",
  "Iota::Schema::Result::UserSession",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 variable_values

Type: has_many

Related object: L<Iota::Schema::Result::VariableValue>

=cut

__PACKAGE__->has_many(
  "variable_values",
  "Iota::Schema::Result::VariableValue",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 variables

Type: has_many

Related object: L<Iota::Schema::Result::Variable>

=cut

__PACKAGE__->has_many(
  "variables",
  "Iota::Schema::Result::Variable",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-03-02 05:51:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hh/L3KCfkk251Fy4KSMg9A

__PACKAGE__->has_many(
    "user_roles",
    "Iota::Schema::Result::UserRole",
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
  "Iota::Schema::Result::Prefeito",
  { "foreign.user_id" => "self.id", }
);

__PACKAGE__->might_have(
  "movimento",
  "Iota::Schema::Result::Movimento",
  { "foreign.user_id" => "self.id" }
);

__PACKAGE__->has_many(
  "sessions",
  "Iota::Schema::Result::UserSession",
  { "foreign.user_id" => "self.id" },
  { cascade_copy      => 0, cascade_delete => 0 },
);


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
