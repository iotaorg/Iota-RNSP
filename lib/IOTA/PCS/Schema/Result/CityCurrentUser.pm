use utf8;
package IOTA::PCS::Schema::Result::CityCurrentUser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IOTA::PCS::Schema::Result::CityCurrentUser

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

=head1 TABLE: C<city_current_user>

=cut

__PACKAGE__->table("city_current_user");

=head1 ACCESSORS

=head2 city_id

  data_type: 'integer'
  is_nullable: 1

=head2 user_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "city_id",
  { data_type => "integer", is_nullable => 1 },
  "user_id",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-03-03 23:16:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ueVyGIfDCex2u1uEW1EgEA


__PACKAGE__->set_primary_key("user_id", "city_id");


__PACKAGE__->belongs_to(
  "user",
  "IOTA::PCS::Schema::Result::User",
  { id => "user_id" },
);

__PACKAGE__->belongs_to(
  "city",
  "IOTA::PCS::Schema::Result::City",
  { id => "city_id" },
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
