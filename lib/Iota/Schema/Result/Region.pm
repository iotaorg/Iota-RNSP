use utf8;
package Iota::Schema::Result::Region;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::Region

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

=head1 TABLE: C<region>

=cut

__PACKAGE__->table("region");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'region_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 name_url

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 city_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 upper_region

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 depth_level

  data_type: 'smallint'
  default_value: 2
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 created_by

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 automatic_fill

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 polygon_path

  data_type: 'text'
  is_nullable: 1

=head2 subregions_valid_after

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "region_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "name_url",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "city_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "upper_region",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "depth_level",
  { data_type => "smallint", default_value => 2, is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "created_by",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "automatic_fill",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "polygon_path",
  { data_type => "text", is_nullable => 1 },
  "subregions_valid_after",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 city

Type: belongs_to

Related object: L<Iota::Schema::Result::City>

=cut

__PACKAGE__->belongs_to(
  "city",
  "Iota::Schema::Result::City",
  { id => "city_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 created_by

Type: belongs_to

Related object: L<Iota::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "created_by",
  "Iota::Schema::Result::User",
  { id => "created_by" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 indicator_values

Type: has_many

Related object: L<Iota::Schema::Result::IndicatorValue>

=cut

__PACKAGE__->has_many(
  "indicator_values",
  "Iota::Schema::Result::IndicatorValue",
  { "foreign.region_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicator_variables_variations_values

Type: has_many

Related object: L<Iota::Schema::Result::IndicatorVariablesVariationsValue>

=cut

__PACKAGE__->has_many(
  "indicator_variables_variations_values",
  "Iota::Schema::Result::IndicatorVariablesVariationsValue",
  { "foreign.region_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 region_variable_values

Type: has_many

Related object: L<Iota::Schema::Result::RegionVariableValue>

=cut

__PACKAGE__->has_many(
  "region_variable_values",
  "Iota::Schema::Result::RegionVariableValue",
  { "foreign.region_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 regions

Type: has_many

Related object: L<Iota::Schema::Result::Region>

=cut

__PACKAGE__->has_many(
  "regions",
  "Iota::Schema::Result::Region",
  { "foreign.upper_region" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 upper_region

Type: belongs_to

Related object: L<Iota::Schema::Result::Region>

=cut

__PACKAGE__->belongs_to(
  "upper_region",
  "Iota::Schema::Result::Region",
  { id => "upper_region" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 user_indicators

Type: has_many

Related object: L<Iota::Schema::Result::UserIndicator>

=cut

__PACKAGE__->has_many(
  "user_indicators",
  "Iota::Schema::Result::UserIndicator",
  { "foreign.region_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_variable_region_configs

Type: has_many

Related object: L<Iota::Schema::Result::UserVariableRegionConfig>

=cut

__PACKAGE__->has_many(
  "user_variable_region_configs",
  "Iota::Schema::Result::UserVariableRegionConfig",
  { "foreign.region_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-12-15 14:24:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:elYr5wa/EG1//7KFe0G7FA

__PACKAGE__->has_many(
  "subregions",
  "Iota::Schema::Result::Region",
  { "foreign.upper_region" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
