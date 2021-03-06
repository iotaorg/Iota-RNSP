use utf8;
package Iota::Schema::Result::UserPage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::UserPage

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

=head1 TABLE: C<user_page>

=cut

__PACKAGE__->table("user_page");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'user_page_id_seq'

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 published_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 title

  data_type: 'text'
  is_nullable: 0

=head2 title_url

  data_type: 'text'
  is_nullable: 0

=head2 content

  data_type: 'text'
  is_nullable: 0

=head2 image_user_file_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 type

  data_type: 'text'
  default_value: 'html'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 template_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "user_page_id_seq",
  },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "published_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "title",
  { data_type => "text", is_nullable => 0 },
  "title_url",
  { data_type => "text", is_nullable => 0 },
  "content",
  { data_type => "text", is_nullable => 0 },
  "image_user_file_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "type",
  {
    data_type     => "text",
    default_value => "html",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "template_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 image_user_file

Type: belongs_to

Related object: L<Iota::Schema::Result::UserFile>

=cut

__PACKAGE__->belongs_to(
  "image_user_file",
  "Iota::Schema::Result::UserFile",
  { id => "image_user_file_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 template

Type: belongs_to

Related object: L<Iota::Schema::Result::UserPage>

=cut

__PACKAGE__->belongs_to(
  "template",
  "Iota::Schema::Result::UserPage",
  { id => "template_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 user

Type: belongs_to

Related object: L<Iota::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Iota::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 user_menus

Type: has_many

Related object: L<Iota::Schema::Result::UserMenu>

=cut

__PACKAGE__->has_many(
  "user_menus",
  "Iota::Schema::Result::UserMenu",
  { "foreign.page_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_pages

Type: has_many

Related object: L<Iota::Schema::Result::UserPage>

=cut

__PACKAGE__->has_many(
  "user_pages",
  "Iota::Schema::Result::UserPage",
  { "foreign.template_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-09-28 06:17:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KjKgv/3MUr4ZB0zOg8zLYw

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
