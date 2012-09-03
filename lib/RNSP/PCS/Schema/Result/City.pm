use utf8;
package RNSP::PCS::Schema::Result::City;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

RNSP::PCS::Schema::Result::City

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

=head1 TABLE: C<city>

=cut

__PACKAGE__->table("city");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'city_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 uf

  data_type: 'text'
  is_nullable: 0

=head2 type

  data_type: 'enum'
  default_value: 'prefeitura'
  extra: {custom_type_name => "city_status_enum",list => ["prefeitura","movimento"]}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "city_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "uf",
  { data_type => "text", is_nullable => 0 },
  "type",
  {
    data_type => "enum",
    default_value => "prefeitura",
    extra => {
      custom_type_name => "city_status_enum",
      list => ["prefeitura", "movimento"],
    },
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<user_city_type_key>

=over 4

=item * L</name>

=item * L</uf>

=item * L</type>

=back

=cut

__PACKAGE__->add_unique_constraint("user_city_type_key", ["name", "uf", "type"]);

=head1 RELATIONS

=head2 users

Type: has_many

Related object: L<RNSP::PCS::Schema::Result::User>

=cut

__PACKAGE__->has_many(
  "users",
  "RNSP::PCS::Schema::Result::User",
  { "foreign.city_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07028 @ 2012-09-03 13:51:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lbVIoy8XkY4eQNwoUy/Grw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
