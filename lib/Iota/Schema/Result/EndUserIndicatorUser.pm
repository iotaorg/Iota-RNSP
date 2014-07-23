use utf8;
package Iota::Schema::Result::EndUserIndicatorUser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::EndUserIndicatorUser

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

=head1 TABLE: C<end_user_indicator_user>

=cut

__PACKAGE__->table("end_user_indicator_user");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'end_user_indicator_user_id_seq'

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 end_user_indicator_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 indicator_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 end_user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "end_user_indicator_user_id_seq",
  },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "end_user_indicator_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "indicator_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "end_user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 end_user

Type: belongs_to

Related object: L<Iota::Schema::Result::EndUser>

=cut

__PACKAGE__->belongs_to(
  "end_user",
  "Iota::Schema::Result::EndUser",
  { id => "end_user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 end_user_indicator

Type: belongs_to

Related object: L<Iota::Schema::Result::EndUserIndicator>

=cut

__PACKAGE__->belongs_to(
  "end_user_indicator",
  "Iota::Schema::Result::EndUserIndicator",
  { id => "end_user_indicator_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2014-06-16 09:41:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:r//kVLPpsPCHB9swIkeOeg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
