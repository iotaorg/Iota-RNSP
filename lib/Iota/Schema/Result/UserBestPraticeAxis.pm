use utf8;
package Iota::Schema::Result::UserBestPraticeAxis;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::UserBestPraticeAxis

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

=head1 TABLE: C<user_best_pratice_axis>

=cut

__PACKAGE__->table("user_best_pratice_axis");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 0

=head2 axis_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 user_best_pratice_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "axis_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "user_best_pratice_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 axis

Type: belongs_to

Related object: L<Iota::Schema::Result::Axis>

=cut

__PACKAGE__->belongs_to(
  "axis",
  "Iota::Schema::Result::Axis",
  { id => "axis_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 user_best_pratice

Type: belongs_to

Related object: L<Iota::Schema::Result::UserBestPratice>

=cut

__PACKAGE__->belongs_to(
  "user_best_pratice",
  "Iota::Schema::Result::UserBestPratice",
  { id => "user_best_pratice_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-06-21 17:49:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bQh7kFiU6Zt6GilS1viuiA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
