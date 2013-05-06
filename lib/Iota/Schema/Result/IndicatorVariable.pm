use utf8;

package Iota::Schema::Result::IndicatorVariable;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::IndicatorVariable

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

__PACKAGE__->load_components( "InflateColumn::DateTime", "TimeStamp", "PassphraseColumn" );

=head1 TABLE: C<indicator_variable>

=cut

__PACKAGE__->table("indicator_variable");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'indicator_variable_id_seq'

=head2 indicator_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 variable_id

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
        sequence          => "indicator_variable_id_seq",
    },
    "indicator_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "variable_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 indicator

Type: belongs_to

Related object: L<Iota::Schema::Result::Indicator>

=cut

__PACKAGE__->belongs_to(
    "indicator",
    "Iota::Schema::Result::Indicator",
    { id            => "indicator_id" },
    { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 variable

Type: belongs_to

Related object: L<Iota::Schema::Result::Variable>

=cut

__PACKAGE__->belongs_to(
    "variable",
    "Iota::Schema::Result::Variable",
    { id            => "variable_id" },
    { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-04-26 09:12:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VIWVpZBTWSRzFaA5VVnpcg

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
