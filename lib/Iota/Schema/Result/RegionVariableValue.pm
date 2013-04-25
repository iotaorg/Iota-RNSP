use utf8;
package Iota::Schema::Result::RegionVariableValue;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::RegionVariableValue

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

=head1 TABLE: C<region_variable_value>

=cut

__PACKAGE__->table("region_variable_value");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'region_variable_value_id_seq'

=head2 region_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 variable_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 value_of_date

  data_type: 'timestamp'
  is_nullable: 1

=head2 valid_from

  data_type: 'date'
  is_nullable: 1

=head2 valid_until

  data_type: 'date'
  is_nullable: 1

=head2 observations

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 source

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 file_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "region_variable_value_id_seq",
  },
  "region_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "variable_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "value_of_date",
  { data_type => "timestamp", is_nullable => 1 },
  "valid_from",
  { data_type => "date", is_nullable => 1 },
  "valid_until",
  { data_type => "date", is_nullable => 1 },
  "observations",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "source",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "file_id",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<region_variable_value_region_id_variable_id_user_id_valid_f_key>

=over 4

=item * L</region_id>

=item * L</variable_id>

=item * L</user_id>

=item * L</valid_from>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "region_variable_value_region_id_variable_id_user_id_valid_f_key",
  ["region_id", "variable_id", "user_id", "valid_from"],
);

=head1 RELATIONS

=head2 region

Type: belongs_to

Related object: L<Iota::Schema::Result::Region>

=cut

__PACKAGE__->belongs_to(
  "region",
  "Iota::Schema::Result::Region",
  { id => "region_id" },
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

=head2 variable

Type: belongs_to

Related object: L<Iota::Schema::Result::Variable>

=cut

__PACKAGE__->belongs_to(
  "variable",
  "Iota::Schema::Result::Variable",
  { id => "variable_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-04-25 18:32:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:STYPUXPcPqjDXVVe5F1wiw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
