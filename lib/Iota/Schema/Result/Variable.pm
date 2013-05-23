use utf8;

package Iota::Schema::Result::Variable;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::Variable

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

=head1 TABLE: C<variable>

=cut

__PACKAGE__->table("variable");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'variable_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 explanation

  data_type: 'text'
  is_nullable: 0

=head2 cognomen

  data_type: 'text'
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 type

  data_type: 'enum'
  default_value: 'str'
  extra: {custom_type_name => "variable_type_enum",list => ["str","int","num"]}
  is_nullable: 0

=head2 period

  data_type: 'enum'
  extra: {custom_type_name => "period_enum",list => ["daily","weekly","monthly","bimonthly","quarterly","semi-annual","yearly","decade"]}
  is_nullable: 0

=head2 source

  data_type: 'text'
  is_nullable: 1

=head2 is_basic

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 measurement_unit_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
    "id",
    {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => "variable_id_seq",
    },
    "name",
    { data_type => "text", is_nullable => 0 },
    "explanation",
    { data_type => "text", is_nullable => 0 },
    "cognomen",
    { data_type => "text", is_nullable => 0 },
    "user_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "created_at",
    {
        data_type     => "timestamp",
        default_value => \"current_timestamp",
        is_nullable   => 1,
        original      => { default_value => \"now()" },
    },
    "type",
    {
        data_type     => "enum",
        default_value => "str",
        extra         => {
            custom_type_name => "variable_type_enum",
            list             => [ "str", "int", "num" ],
        },
        is_nullable => 0,
    },
    "period",
    {
        data_type => "enum",
        extra     => {
            custom_type_name => "period_enum",
            list => [ "daily", "weekly", "monthly", "bimonthly", "quarterly", "semi-annual", "yearly", "decade", ],
        },
        is_nullable => 0,
    },
    "source",
    { data_type => "text", is_nullable => 1 },
    "is_basic",
    { data_type => "boolean", default_value => \"false", is_nullable => 1 },
    "measurement_unit_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<variable_cognomen_key>

=over 4

=item * L</cognomen>

=back

=cut

__PACKAGE__->add_unique_constraint( "variable_cognomen_key", ["cognomen"] );

=head1 RELATIONS

=head2 indicator_variables

Type: has_many

Related object: L<Iota::Schema::Result::IndicatorVariable>

=cut

__PACKAGE__->has_many(
    "indicator_variables", "Iota::Schema::Result::IndicatorVariable",
    { "foreign.variable_id" => "self.id" }, { cascade_copy => 0, cascade_delete => 0 },
);

=head2 measurement_unit

Type: belongs_to

Related object: L<Iota::Schema::Result::MeasurementUnit>

=cut

__PACKAGE__->belongs_to(
    "measurement_unit",
    "Iota::Schema::Result::MeasurementUnit",
    { id => "measurement_unit_id" },
    {
        is_deferrable => 0,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

=head2 region_variable_values

Type: has_many

Related object: L<Iota::Schema::Result::RegionVariableValue>

=cut

__PACKAGE__->has_many(
    "region_variable_values", "Iota::Schema::Result::RegionVariableValue",
    { "foreign.variable_id" => "self.id" }, { cascade_copy => 0, cascade_delete => 0 },
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

=head2 user_variable_configs

Type: has_many

Related object: L<Iota::Schema::Result::UserVariableConfig>

=cut

__PACKAGE__->has_many(
    "user_variable_configs", "Iota::Schema::Result::UserVariableConfig",
    { "foreign.variable_id" => "self.id" }, { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_variable_region_configs

Type: has_many

Related object: L<Iota::Schema::Result::UserVariableRegionConfig>

=cut

__PACKAGE__->has_many(
    "user_variable_region_configs", "Iota::Schema::Result::UserVariableRegionConfig",
    { "foreign.variable_id" => "self.id" }, { cascade_copy => 0, cascade_delete => 0 },
);

=head2 variable_values

Type: has_many

Related object: L<Iota::Schema::Result::VariableValue>

=cut

__PACKAGE__->has_many(
    "variable_values", "Iota::Schema::Result::VariableValue",
    { "foreign.variable_id" => "self.id" }, { cascade_copy => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-05-06 05:58:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:otFHzoS3lYeJheWzzAXLlA

__PACKAGE__->belongs_to(
    "owner", "Iota::Schema::Result::User",
    { "foreign.id"  => "self.user_id" },
    { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->has_many( "values", "Iota::Schema::Result::VariableValue", { "foreign.variable_id" => "self.id" }, );

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
