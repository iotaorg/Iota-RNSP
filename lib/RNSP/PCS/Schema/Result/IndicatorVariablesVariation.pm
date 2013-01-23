use utf8;
package RNSP::PCS::Schema::Result::IndicatorVariablesVariation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

RNSP::PCS::Schema::Result::IndicatorVariablesVariation

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

=head1 TABLE: C<indicator_variables_variations>

=cut

__PACKAGE__->table("indicator_variables_variations");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'indicator_variables_variations_id_seq'

=head2 indicator_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 type

  data_type: 'enum'
  default_value: 'int'
  extra: {custom_type_name => "variable_type_enum",list => ["str","int","num"]}
  is_nullable: 0

=head2 explanation

  data_type: 'text'
  is_nullable: 1

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
    sequence          => "indicator_variables_variations_id_seq",
  },
  "indicator_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "type",
  {
    data_type => "enum",
    default_value => "int",
    extra => {
      custom_type_name => "variable_type_enum",
      list => ["str", "int", "num"],
    },
    is_nullable => 0,
  },
  "explanation",
  { data_type => "text", is_nullable => 1 },
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

=head1 RELATIONS

=head2 indicator

Type: belongs_to

Related object: L<RNSP::PCS::Schema::Result::Indicator>

=cut

__PACKAGE__->belongs_to(
  "indicator",
  "RNSP::PCS::Schema::Result::Indicator",
  { id => "indicator_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 indicator_variables_variations_values

Type: has_many

Related object: L<RNSP::PCS::Schema::Result::IndicatorVariablesVariationsValue>

=cut

__PACKAGE__->has_many(
  "indicator_variables_variations_values",
  "RNSP::PCS::Schema::Result::IndicatorVariablesVariationsValue",
  { "foreign.indicator_variables_variation_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-01-23 04:12:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:f5CEh9Rdmp72SMfDkOfT/A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
