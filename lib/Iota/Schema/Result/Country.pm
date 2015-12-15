use utf8;
package Iota::Schema::Result::Country;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::Country

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

=head1 TABLE: C<country>

=cut

__PACKAGE__->table("country");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'country_id_seq'

=head2 name_url

  data_type: 'text'
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 created_by

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "country_id_seq",
  },
  "name_url",
  { data_type => "text", is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "created_by",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<country_name_uri_key>

=over 4

=item * L</name_url>

=back

=cut

__PACKAGE__->add_unique_constraint("country_name_uri_key", ["name_url"]);

=head1 RELATIONS

=head2 cities

Type: has_many

Related object: L<Iota::Schema::Result::City>

=cut

__PACKAGE__->has_many(
  "cities",
  "Iota::Schema::Result::City",
  { "foreign.country_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 states

Type: has_many

Related object: L<Iota::Schema::Result::State>

=cut

__PACKAGE__->has_many(
  "states",
  "Iota::Schema::Result::State",
  { "foreign.country_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-12-14 17:32:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Y7dDtwW0q83BQtCYm3R9wg

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
