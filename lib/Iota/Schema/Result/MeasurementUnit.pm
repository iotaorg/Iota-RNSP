use utf8;
package Iota::Schema::Result::MeasurementUnit;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::MeasurementUnit

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

=head1 TABLE: C<measurement_unit>

=cut

__PACKAGE__->table("measurement_unit");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'measurement_unit_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 short_name

  data_type: 'text'
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
    sequence          => "measurement_unit_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 1 },
  "short_name",
  { data_type => "text", is_nullable => 1 },
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

=head1 RELATIONS

=head2 variables

Type: has_many

Related object: L<Iota::Schema::Result::Variable>

=cut

__PACKAGE__->has_many(
  "variables",
  "Iota::Schema::Result::Variable",
  { "foreign.measurement_unit_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-02-08 18:32:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lgYnEJCk7uAwjGgniN5c/A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
