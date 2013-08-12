use utf8;
package Iota::Schema::Result::DownloadVariable;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::DownloadVariable

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

=head1 TABLE: C<download_variable>

=cut

__PACKAGE__->table("download_variable");

=head1 ACCESSORS

=head2 city_id

  data_type: 'integer'
  is_nullable: 1

=head2 city_name

  data_type: 'text'
  is_nullable: 1

=head2 variable_id

  data_type: 'integer'
  is_nullable: 1

=head2 type

  data_type: 'enum'
  extra: {custom_type_name => "variable_type_enum",list => ["str","int","num"]}
  is_nullable: 1

=head2 cognomen

  data_type: 'text'
  is_nullable: 1

=head2 period

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 exp_source

  data_type: 'text'
  is_nullable: 1

=head2 is_basic

  data_type: 'boolean'
  is_nullable: 1

=head2 measurement_unit_name

  data_type: 'text'
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 valid_from

  data_type: 'date'
  is_nullable: 1

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 observations

  data_type: 'text'
  is_nullable: 1

=head2 source

  data_type: 'text'
  is_nullable: 1

=head2 user_id

  data_type: 'integer'
  is_nullable: 1

=head2 institute_id

  data_type: 'integer'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "city_id",
  { data_type => "integer", is_nullable => 1 },
  "city_name",
  { data_type => "text", is_nullable => 1 },
  "variable_id",
  { data_type => "integer", is_nullable => 1 },
  "type",
  {
    data_type => "enum",
    extra => {
      custom_type_name => "variable_type_enum",
      list => ["str", "int", "num"],
    },
    is_nullable => 1,
  },
  "cognomen",
  { data_type => "text", is_nullable => 1 },
  "period",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "exp_source",
  { data_type => "text", is_nullable => 1 },
  "is_basic",
  { data_type => "boolean", is_nullable => 1 },
  "measurement_unit_name",
  { data_type => "text", is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "valid_from",
  { data_type => "date", is_nullable => 1 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "observations",
  { data_type => "text", is_nullable => 1 },
  "source",
  { data_type => "text", is_nullable => 1 },
  "user_id",
  { data_type => "integer", is_nullable => 1 },
  "institute_id",
  { data_type => "integer", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-08-12 15:08:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1IMQ0Q50CB3czSc+ZxlI9Q

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
