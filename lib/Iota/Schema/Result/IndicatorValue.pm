use utf8;
package Iota::Schema::Result::IndicatorValue;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::IndicatorValue

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

=head1 TABLE: C<indicator_values>

=cut

__PACKAGE__->table("indicator_values");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 0

=head2 indicator_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 valid_from

  data_type: 'date'
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 city_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 state_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 country_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 institute_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 variation_name

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 aggregated_by

  data_type: 'enum'
  extra: {custom_type_name => "period_enum",list => ["daily","weekly","monthly","bimonthly","quarterly","semi-annual","yearly","decade"]}
  is_nullable: 0

=head2 updated_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "indicator_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "valid_from",
  { data_type => "date", is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "city_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "state_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "country_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "institute_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "variation_name",
  {
    data_type     => "text",
    default_value => "",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "aggregated_by",
  {
    data_type => "enum",
    extra => {
      custom_type_name => "period_enum",
      list => [
        "daily",
        "weekly",
        "monthly",
        "bimonthly",
        "quarterly",
        "semi-annual",
        "yearly",
        "decade",
      ],
    },
    is_nullable => 0,
  },
  "updated_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
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

=head2 C<indicator_values_indicator_id_valid_from_aggregated_by_user_key>

=over 4

=item * L</indicator_id>

=item * L</valid_from>

=item * L</aggregated_by>

=item * L</user_id>

=item * L</variation_name>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "indicator_values_indicator_id_valid_from_aggregated_by_user_key",
  [
    "indicator_id",
    "valid_from",
    "aggregated_by",
    "user_id",
    "variation_name",
  ],
);

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

=head2 country

Type: belongs_to

Related object: L<Iota::Schema::Result::Country>

=cut

__PACKAGE__->belongs_to(
  "country",
  "Iota::Schema::Result::Country",
  { id => "country_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 indicator

Type: belongs_to

Related object: L<Iota::Schema::Result::Indicator>

=cut

__PACKAGE__->belongs_to(
  "indicator",
  "Iota::Schema::Result::Indicator",
  { id => "indicator_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 institute

Type: belongs_to

Related object: L<Iota::Schema::Result::Institute>

=cut

__PACKAGE__->belongs_to(
  "institute",
  "Iota::Schema::Result::Institute",
  { id => "institute_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 state

Type: belongs_to

Related object: L<Iota::Schema::Result::State>

=cut

__PACKAGE__->belongs_to(
  "state",
  "Iota::Schema::Result::State",
  { id => "state_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 user

Type: belongs_to

Related object: L<Iota::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Iota::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-04-25 18:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RnqYs4wXskqVp7h4B6ty5Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
