use utf8;
package Iota::PCS::Schema::Result::IndicatorNetworkConfig;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::PCS::Schema::Result::IndicatorNetworkConfig

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

=head1 TABLE: C<indicator_network_config>

=cut

__PACKAGE__->table("indicator_network_config");

=head1 ACCESSORS

=head2 indicator_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 network_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 unfolded_in_home

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "indicator_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "network_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "unfolded_in_home",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</indicator_id>

=item * L</network_id>

=back

=cut

__PACKAGE__->set_primary_key("indicator_id", "network_id");

=head1 RELATIONS

=head2 indicator

Type: belongs_to

Related object: L<Iota::PCS::Schema::Result::Indicator>

=cut

__PACKAGE__->belongs_to(
  "indicator",
  "Iota::PCS::Schema::Result::Indicator",
  { id => "indicator_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 network

Type: belongs_to

Related object: L<Iota::PCS::Schema::Result::Network>

=cut

__PACKAGE__->belongs_to(
  "network",
  "Iota::PCS::Schema::Result::Network",
  { id => "network_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-03-02 04:07:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4hSSulLOK9uCAPZywyBk0Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
