use utf8;
package Iota::Schema::Result::RegionConfig;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::RegionConfig

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

=head1 TABLE: C<region_config>

=cut

__PACKAGE__->table("region_config");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'region_config_id_seq'

=head2 institute_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 aggregate_only_if_full

  data_type: 'boolean'
  is_nullable: 0

apenas faz as contas se as regioes abaixos estao com todas as variaveis preenchidas

=head2 active_me_when_empty

  data_type: 'boolean'
  is_nullable: 0

o dado da regiao acima ira se consolidar como ativo caso nao exista valores para as subs.

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "region_config_id_seq",
  },
  "institute_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "aggregate_only_if_full",
  { data_type => "boolean", is_nullable => 0 },
  "active_me_when_empty",
  { data_type => "boolean", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<region_config_institute_id_region_id_key>

=over 4

=item * L</institute_id>

=back

=cut

__PACKAGE__->add_unique_constraint("region_config_institute_id_region_id_key", ["institute_id"]);

=head1 RELATIONS

=head2 institute

Type: belongs_to

Related object: L<Iota::Schema::Result::Institute>

=cut

__PACKAGE__->belongs_to(
  "institute",
  "Iota::Schema::Result::Institute",
  { id => "institute_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2014-04-04 08:44:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:skdOiTrL+mg3I1IQcCvGIA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
