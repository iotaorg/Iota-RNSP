use utf8;
package Iota::Schema::Result::EndUserIndicator;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::EndUserIndicator

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

=head1 TABLE: C<end_user_indicator>

=cut

__PACKAGE__->table("end_user_indicator");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'end_user_indicator_id_seq'

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 end_user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 indicator_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 all_users

  data_type: 'boolean'
  is_nullable: 0

=head2 network_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "end_user_indicator_id_seq",
  },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "end_user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "indicator_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "all_users",
  { data_type => "boolean", is_nullable => 0 },
  "network_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
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

=head2 end_user_indicator_users

Type: has_many

Related object: L<Iota::Schema::Result::EndUserIndicatorUser>

=cut

__PACKAGE__->has_many(
  "end_user_indicator_users",
  "Iota::Schema::Result::EndUserIndicatorUser",
  { "foreign.end_user_indicator_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

=head2 network

Type: belongs_to

Related object: L<Iota::Schema::Result::Network>

=cut

__PACKAGE__->belongs_to(
  "network",
  "Iota::Schema::Result::Network",
  { id => "network_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2014-06-30 08:41:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YZ4R4+Pxf1U58xtH7igaYA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
