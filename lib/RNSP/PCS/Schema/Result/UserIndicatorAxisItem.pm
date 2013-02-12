use utf8;
package RNSP::PCS::Schema::Result::UserIndicatorAxisItem;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

RNSP::PCS::Schema::Result::UserIndicatorAxisItem

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

=head1 TABLE: C<user_indicator_axis_item>

=cut

__PACKAGE__->table("user_indicator_axis_item");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'user_indicator_axis_item_id_seq'

=head2 user_indicator_axis_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 indicator_id

  data_type: 'integer'
  is_nullable: 0

=head2 position

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "user_indicator_axis_item_id_seq",
  },
  "user_indicator_axis_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "indicator_id",
  { data_type => "integer", is_nullable => 0 },
  "position",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 user_indicator_axis

Type: belongs_to

Related object: L<RNSP::PCS::Schema::Result::UserIndicatorAxis>

=cut

__PACKAGE__->belongs_to(
  "user_indicator_axis",
  "RNSP::PCS::Schema::Result::UserIndicatorAxis",
  { id => "user_indicator_axis_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-02-11 22:12:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:F0EfrZuci7SOxAciwzxlVA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
