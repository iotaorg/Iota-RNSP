use utf8;

package Iota::Schema::Result::IndicatorVariablesVariationsValue;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::IndicatorVariablesVariationsValue

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

=head1 TABLE: C<indicator_variables_variations_value>

=cut

__PACKAGE__->table("indicator_variables_variations_value");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'indicator_variables_variations_value_id_seq'

=head2 indicator_variation_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 indicator_variables_variation_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 value_of_date

  data_type: 'timestamp'
  is_nullable: 1

=head2 valid_from

  data_type: 'date'
  is_nullable: 1

=head2 valid_until

  data_type: 'date'
  is_nullable: 1

=head2 user_id

  data_type: 'integer'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 region_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 generated_by_compute

  data_type: 'boolean'
  is_nullable: 1

=head2 active_value

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "id",
    {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => "indicator_variables_variations_value_id_seq",
    },
    "indicator_variation_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "indicator_variables_variation_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "value",
    { data_type => "text", is_nullable => 1 },
    "value_of_date",
    { data_type => "timestamp", is_nullable => 1 },
    "valid_from",
    { data_type => "date", is_nullable => 1 },
    "valid_until",
    { data_type => "date", is_nullable => 1 },
    "user_id",
    { data_type => "integer", is_nullable => 0 },
    "created_at",
    {
        data_type     => "timestamp",
        default_value => \"current_timestamp",
        is_nullable   => 1,
        original      => { default_value => \"now()" },
    },
    "region_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "generated_by_compute",
    { data_type => "boolean", is_nullable => 1 },
    "active_value",
    { data_type => "boolean", default_value => \"true", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 indicator_variables_variation

Type: belongs_to

Related object: L<Iota::Schema::Result::IndicatorVariablesVariation>

=cut

__PACKAGE__->belongs_to(
    "indicator_variables_variation",
    "Iota::Schema::Result::IndicatorVariablesVariation",
    { id            => "indicator_variables_variation_id" },
    { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 indicator_variation

Type: belongs_to

Related object: L<Iota::Schema::Result::IndicatorVariation>

=cut

__PACKAGE__->belongs_to(
    "indicator_variation",
    "Iota::Schema::Result::IndicatorVariation",
    { id            => "indicator_variation_id" },
    { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 region

Type: belongs_to

Related object: L<Iota::Schema::Result::Region>

=cut

__PACKAGE__->belongs_to(
    "region",
    "Iota::Schema::Result::Region",
    { id => "region_id" },
    {
        is_deferrable => 0,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-01 12:09:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fmkr1k68uDsmUk34bLfuOQ

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
