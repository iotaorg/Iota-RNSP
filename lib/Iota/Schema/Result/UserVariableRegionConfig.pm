use utf8;

package Iota::Schema::Result::UserVariableRegionConfig;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::UserVariableRegionConfig

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

=head1 TABLE: C<user_variable_region_config>

=cut

__PACKAGE__->table("user_variable_region_config");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'user_variable_region_config_id_seq'

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 region_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 variable_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 display_in_home

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

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
        sequence          => "user_variable_region_config_id_seq",
    },
    "user_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "region_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "variable_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "display_in_home",
    { data_type => "boolean", default_value => \"true", is_nullable => 0 },
    "created_at",
    {
        data_type     => "timestamp",
        default_value => \"current_timestamp",
        is_nullable   => 1,
        original      => { default_value => \"now()" },
    },
    "position",
    { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<user_variable_region_config_user_id_region_id_variable_id_key>

=over 4

=item * L</user_id>

=item * L</region_id>

=item * L</variable_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
    "user_variable_region_config_user_id_region_id_variable_id_key",
    [ "user_id", "region_id", "variable_id" ],
);

=head1 RELATIONS

=head2 region

Type: belongs_to

Related object: L<Iota::Schema::Result::Region>

=cut

__PACKAGE__->belongs_to(
    "region",
    "Iota::Schema::Result::Region",
    { id            => "region_id" },
    { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 user

Type: belongs_to

Related object: L<Iota::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
    "user", "Iota::Schema::Result::User",
    { id            => "user_id" },
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

# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-05-09 07:45:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:X9cFNXgG5GflcZQNLx10oQ

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
