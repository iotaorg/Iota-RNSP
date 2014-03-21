use utf8;
package Iota::Schema::Result::IndicatorNetworkVisibility;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::IndicatorNetworkVisibility

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

=head1 TABLE: C<indicator_network_visibility>

=cut

__PACKAGE__->table("indicator_network_visibility");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'indicator_network_visibility_id_seq'

=head2 indicator_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 network_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 created_by

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
    sequence          => "indicator_network_visibility_id_seq",
  },
  "indicator_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "network_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "created_by",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 created_by

Type: belongs_to

Related object: L<Iota::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "created_by",
  "Iota::Schema::Result::User",
  { id => "created_by" },
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
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 network

Type: belongs_to

Related object: L<Iota::Schema::Result::Network>

=cut

__PACKAGE__->belongs_to(
  "network",
  "Iota::Schema::Result::Network",
  { id => "network_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2014-03-20 09:10:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IjvTqP8L4BRNdGqAilbx8A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
