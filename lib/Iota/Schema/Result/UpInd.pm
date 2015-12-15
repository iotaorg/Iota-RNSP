use utf8;
package Iota::Schema::Result::UpInd;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::UpInd

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

=head1 TABLE: C<up_ind>

=cut

__PACKAGE__->table("up_ind");

=head1 ACCESSORS

=head2 name

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 name_url

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 formula

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 goal

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 goal_explanation

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 goal_source

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 goal_operator

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 axis_id

  data_type: 'integer'
  is_nullable: 1

=head2 source

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 explanation

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 sort_direction

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 obs

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "name",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "name_url",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "formula",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "goal",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "goal_explanation",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "goal_source",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "goal_operator",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "axis_id",
  { data_type => "integer", is_nullable => 1 },
  "source",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "explanation",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "sort_direction",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "obs",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-12-14 17:32:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:T1J3QOTa9by6bdWiPcMWNA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
