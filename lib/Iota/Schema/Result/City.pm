use utf8;
package Iota::Schema::Result::City;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::City

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

=head1 TABLE: C<city>

=cut

__PACKAGE__->table("city");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'city_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 uf

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 pais

  data_type: 'text'
  default_value: 'br'
  is_nullable: 1

=head2 latitude

  data_type: 'double precision'
  is_nullable: 1

=head2 longitude

  data_type: 'double precision'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 name_uri

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 telefone_prefeitura

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 endereco_prefeitura

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 bairro_prefeitura

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 cep_prefeitura

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 email_prefeitura

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 nome_responsavel_prefeitura

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 summary

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 state_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 country_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 automatic_fill

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "city_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "uf",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "pais",
  { data_type => "text", default_value => "br", is_nullable => 1 },
  "latitude",
  { data_type => "double precision", is_nullable => 1 },
  "longitude",
  { data_type => "double precision", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "name_uri",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "telefone_prefeitura",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "endereco_prefeitura",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "bairro_prefeitura",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "cep_prefeitura",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "email_prefeitura",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "nome_responsavel_prefeitura",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "summary",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "state_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "country_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "automatic_fill",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<city_pais_uf_name_uri_key>

=over 4

=item * L</pais>

=item * L</uf>

=item * L</name_uri>

=back

=cut

__PACKAGE__->add_unique_constraint("city_pais_uf_name_uri_key", ["pais", "uf", "name_uri"]);

=head1 RELATIONS

=head2 country

Type: belongs_to

Related object: L<Iota::Schema::Result::Country>

=cut

__PACKAGE__->belongs_to(
  "country",
  "Iota::Schema::Result::Country",
  { id => "country_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 indicator_values

Type: has_many

Related object: L<Iota::Schema::Result::IndicatorValue>

=cut

__PACKAGE__->has_many(
  "indicator_values",
  "Iota::Schema::Result::IndicatorValue",
  { "foreign.city_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 regions

Type: has_many

Related object: L<Iota::Schema::Result::Region>

=cut

__PACKAGE__->has_many(
  "regions",
  "Iota::Schema::Result::Region",
  { "foreign.city_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 state

Type: belongs_to

Related object: L<Iota::Schema::Result::State>

=cut

__PACKAGE__->belongs_to(
  "state",
  "Iota::Schema::Result::State",
  { id => "state_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 users

Type: has_many

Related object: L<Iota::Schema::Result::User>

=cut

__PACKAGE__->has_many(
  "users",
  "Iota::Schema::Result::User",
  { "foreign.city_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-12-14 17:32:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:S/jE7jh/kawcBUiI64RwIQ

__PACKAGE__->has_many( "current_users", "Iota::Schema::Result::CityCurrentUser", { "foreign.city_id" => "self.id" }, );

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
