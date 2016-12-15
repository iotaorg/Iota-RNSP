use utf8;
package Iota::Schema::Result::Institute;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::Institute

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

=head1 TABLE: C<institute>

=cut

__PACKAGE__->table("institute");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'institute_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 short_name

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 users_can_edit_value

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 users_can_edit_groups

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 can_use_custom_css

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 can_use_custom_pages

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 bypass_indicator_axis_if_custom

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 hide_empty_indicators

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 license

  data_type: 'text'
  is_nullable: 1

=head2 license_url

  data_type: 'text'
  is_nullable: 1

=head2 image_url

  data_type: 'text'
  is_nullable: 1

=head2 datapackage_autor

  data_type: 'text'
  is_nullable: 1

=head2 datapackage_autor_email

  data_type: 'text'
  is_nullable: 1

=head2 can_use_regions

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 can_create_indicators

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 fixed_indicator_axis_id

  data_type: 'integer'
  is_nullable: 1

=head2 aggregate_only_if_full

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

apenas faz as contas se as regioes abaixos estao com todas as variaveis preenchidas

=head2 active_me_when_empty

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

o dado da regiao acima ira se consolidar como ativo caso nao exista valores para as subs.

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "institute_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "short_name",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "users_can_edit_value",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "users_can_edit_groups",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "can_use_custom_css",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "can_use_custom_pages",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "bypass_indicator_axis_if_custom",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "hide_empty_indicators",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "license",
  { data_type => "text", is_nullable => 1 },
  "license_url",
  { data_type => "text", is_nullable => 1 },
  "image_url",
  { data_type => "text", is_nullable => 1 },
  "datapackage_autor",
  { data_type => "text", is_nullable => 1 },
  "datapackage_autor_email",
  { data_type => "text", is_nullable => 1 },
  "can_use_regions",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "can_create_indicators",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "fixed_indicator_axis_id",
  { data_type => "integer", is_nullable => 1 },
  "aggregate_only_if_full",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "active_me_when_empty",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<institute_short_name_key>

=over 4

=item * L</short_name>

=back

=cut

__PACKAGE__->add_unique_constraint("institute_short_name_key", ["short_name"]);

=head1 RELATIONS

=head2 indicator_values

Type: has_many

Related object: L<Iota::Schema::Result::IndicatorValue>

=cut

__PACKAGE__->has_many(
  "indicator_values",
  "Iota::Schema::Result::IndicatorValue",
  { "foreign.institute_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 networks

Type: has_many

Related object: L<Iota::Schema::Result::Network>

=cut

__PACKAGE__->has_many(
  "networks",
  "Iota::Schema::Result::Network",
  { "foreign.institute_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 users

Type: has_many

Related object: L<Iota::Schema::Result::User>

=cut

__PACKAGE__->has_many(
  "users",
  "Iota::Schema::Result::User",
  { "foreign.institute_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-12-15 14:24:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3NawtKbYjXds2QofFa3lJA


use JSON;
sub build_metadata {

    my ($self) = @_;

    return eval{decode_json($self->metadata)};
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
