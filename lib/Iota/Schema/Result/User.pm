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

=head2 password

  data_type: 'text'
  is_nullable: 0

=head2 estado

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 cidade

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 bairro

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 cep

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 telefone

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 email_contato

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 telefone_contato

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 nome_responsavel_cadastro

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 endereco

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 city_summary

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 active

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 institute_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 cur_lang

  data_type: 'text'
  default_value: 'pt-br'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 regions_enabled

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 can_create_indicators

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 _keep_password

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

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
  "estado",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "cidade",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "bairro",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "cep",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "telefone",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "email_contato",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "telefone_contato",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "nome_responsavel_cadastro",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "endereco",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "city_summary",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "active",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "institute_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "cur_lang",
  {
    data_type     => "text",
    default_value => "pt-br",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "regions_enabled",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "can_create_indicators",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "_keep_password",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
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

=head2 indicator_network_visibilities

Type: has_many

Related object: L<Iota::Schema::Result::IndicatorNetworkVisibility>

=cut

__PACKAGE__->has_many(
  "indicator_network_visibilities",
  "Iota::Schema::Result::IndicatorNetworkVisibility",
  { "foreign.created_by" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

=head2 indicator_values

Type: has_many

Related object: L<Iota::Schema::Result::IndicatorValue>

=cut

__PACKAGE__->has_many(
  "indicator_values",
  "Iota::Schema::Result::IndicatorValue",
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

=head2 indicator_visibility_users

Type: has_many

Related object: L<Iota::Schema::Result::Indicator>

=cut

__PACKAGE__->has_many(
  "indicator_visibility_users",
  "Iota::Schema::Result::Indicator",
  { "foreign.visibility_user_id" => "self.id" },
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

=head2 institute

Type: belongs_to

Related object: L<Iota::Schema::Result::Institute>

=cut

__PACKAGE__->belongs_to(
  "institute",
  "Iota::Schema::Result::Institute",
  { id => "institute_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 network_users

Type: has_many

Related object: L<Iota::Schema::Result::NetworkUser>

=cut

__PACKAGE__->has_many(
  "network_users",
  "Iota::Schema::Result::NetworkUser",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 region_variable_values

Type: has_many

Related object: L<Iota::Schema::Result::RegionVariableValue>

=cut

__PACKAGE__->has_many(
  "region_variable_values",
  "Iota::Schema::Result::RegionVariableValue",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 region_variable_values_cloned_from_user

Type: has_many

Related object: L<Iota::Schema::Result::RegionVariableValue>

=cut

__PACKAGE__->has_many(
  "region_variable_values_cloned_from_user",
  "Iota::Schema::Result::RegionVariableValue",
  { "foreign.cloned_from_user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 regions

Type: has_many

Related object: L<Iota::Schema::Result::Region>

=cut

__PACKAGE__->has_many(
  "regions",
  "Iota::Schema::Result::Region",
  { "foreign.created_by" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

=head2 user_best_pratices

Type: has_many

Related object: L<Iota::Schema::Result::UserBestPratice>

=cut

__PACKAGE__->has_many(
  "user_best_pratices",
  "Iota::Schema::Result::UserBestPratice",
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

=head2 user_menus

Type: has_many

Related object: L<Iota::Schema::Result::UserMenu>

=cut

__PACKAGE__->has_many(
  "user_menus",
  "Iota::Schema::Result::UserMenu",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_pages

Type: has_many

Related object: L<Iota::Schema::Result::UserPage>

=cut

__PACKAGE__->has_many(
  "user_pages",
  "Iota::Schema::Result::UserPage",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_regions

Type: has_many

Related object: L<Iota::Schema::Result::UserRegion>

=cut

__PACKAGE__->has_many(
  "user_regions",
  "Iota::Schema::Result::UserRegion",
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

=head2 user_variable_configs

Type: has_many

Related object: L<Iota::Schema::Result::UserVariableConfig>

=cut

__PACKAGE__->has_many(
  "user_variable_configs",
  "Iota::Schema::Result::UserVariableConfig",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_variable_region_configs

Type: has_many

Related object: L<Iota::Schema::Result::UserVariableRegionConfig>

=cut

__PACKAGE__->has_many(
  "user_variable_region_configs",
  "Iota::Schema::Result::UserVariableRegionConfig",
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

=head2 variable_values_cloned_from_user

Type: has_many

Related object: L<Iota::Schema::Result::VariableValue>

=cut

__PACKAGE__->has_many(
  "variable_values_cloned_from_user",
  "Iota::Schema::Result::VariableValue",
  { "foreign.cloned_from_user" => "self.id" },
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

=head2 networks

Type: many_to_many

Composing rels: L</network_users> -> network

=cut

__PACKAGE__->many_to_many("networks", "network_users", "network");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-12-14 17:32:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CjeYuaFMS4vNYCFQeCfi4w

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

__PACKAGE__->has_many(
    "sessions",
    "Iota::Schema::Result::UserSession",
    { "foreign.user_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
