use utf8;
package Iota::Schema::Result::Axis;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::Axis

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

=head1 TABLE: C<axis>

=cut

__PACKAGE__->table("axis");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'axis_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 attrs

  data_type: 'integer[]'
  is_nullable: 1

=head2 description

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "axis_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "attrs",
  { data_type => "integer[]", is_nullable => 1 },
  "description",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 indicators

Type: has_many

Related object: L<Iota::Schema::Result::Indicator>

=cut

__PACKAGE__->has_many(
  "indicators",
  "Iota::Schema::Result::Indicator",
  { "foreign.axis_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_best_pratice_axes

Type: has_many

Related object: L<Iota::Schema::Result::UserBestPraticeAxis>

=cut

__PACKAGE__->has_many(
  "user_best_pratice_axes",
  "Iota::Schema::Result::UserBestPraticeAxis",
  { "foreign.axis_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_best_pratices

Type: has_many

Related object: L<Iota::Schema::Result::UserBestPratice>

=cut

__PACKAGE__->has_many(
  "user_best_pratices",
  "Iota::Schema::Result::UserBestPratice",
  { "foreign.axis_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-08-14 14:16:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LrDGv9LMaSibdOCZdgzAKA

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
