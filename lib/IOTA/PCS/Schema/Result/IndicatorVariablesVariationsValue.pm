use utf8;
package IOTA::PCS::Schema::Result::IndicatorVariablesVariationsValue;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IOTA::PCS::Schema::Result::IndicatorVariablesVariationsValue

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
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<indicator_variables_variation_indicator_variation_id_indica_key>

=over 4

=item * L</indicator_variation_id>

=item * L</indicator_variables_variation_id>

=item * L</valid_from>

=item * L</user_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "indicator_variables_variation_indicator_variation_id_indica_key",
  [
    "indicator_variation_id",
    "indicator_variables_variation_id",
    "valid_from",
    "user_id",
  ],
);

=head1 RELATIONS

=head2 indicator_variables_variation

Type: belongs_to

Related object: L<IOTA::PCS::Schema::Result::IndicatorVariablesVariation>

=cut

__PACKAGE__->belongs_to(
  "indicator_variables_variation",
  "IOTA::PCS::Schema::Result::IndicatorVariablesVariation",
  { id => "indicator_variables_variation_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 indicator_variation

Type: belongs_to

Related object: L<IOTA::PCS::Schema::Result::IndicatorVariation>

=cut

__PACKAGE__->belongs_to(
  "indicator_variation",
  "IOTA::PCS::Schema::Result::IndicatorVariation",
  { id => "indicator_variation_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-21 16:45:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BNKTqhDLfJEvUJC5RmZtEw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
