use utf8;

package Iota::Schema::Result::UserFile;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::UserFile

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

=head1 TABLE: C<user_file>

=cut

__PACKAGE__->table("user_file");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'user_file_id_seq'

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 class_name

  data_type: 'text'
  default_value: 'perfil'
  is_nullable: 0

=head2 public_url

  data_type: 'text'
  is_nullable: 0

=head2 private_path

  data_type: 'text'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 hide_listing

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 public_name

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
    "id",
    {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => "user_file_id_seq",
    },
    "user_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "class_name",
    { data_type => "text", default_value => "perfil", is_nullable => 0 },
    "public_url",
    { data_type => "text", is_nullable => 0 },
    "private_path",
    { data_type => "text", is_nullable => 0 },
    "created_at",
    {
        data_type     => "timestamp",
        default_value => \"current_timestamp",
        is_nullable   => 0,
        original      => { default_value => \"now()" },
    },
    "hide_listing",
    { data_type => "boolean", default_value => \"true", is_nullable => 0 },
    "description",
    {
        data_type   => "text",
        is_nullable => 1,
        original    => { data_type => "varchar" },
    },
    "public_name",
    {
        data_type   => "text",
        is_nullable => 1,
        original    => { data_type => "varchar" },
    },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 user

Type: belongs_to

Related object: L<Iota::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
    "user", "Iota::Schema::Result::User",
    { id            => "user_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-08 17:50:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JSCpXXVvG6TOYemYr2iahA

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
