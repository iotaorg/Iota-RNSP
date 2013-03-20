use utf8;
package Iota::Schema::Result::UserMenu;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::UserMenu

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

=head1 TABLE: C<user_menu>

=cut

__PACKAGE__->table("user_menu");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'user_menu_id_seq'

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 page_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 0

=head2 position

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 menu_id

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
    sequence          => "user_menu_id_seq",
  },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "page_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 0 },
  "position",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "menu_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 menu

Type: belongs_to

Related object: L<Iota::Schema::Result::UserMenu>

=cut

__PACKAGE__->belongs_to(
  "menu",
  "Iota::Schema::Result::UserMenu",
  { id => "menu_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 page

Type: belongs_to

Related object: L<Iota::Schema::Result::UserPage>

=cut

__PACKAGE__->belongs_to(
  "page",
  "Iota::Schema::Result::UserPage",
  { id => "page_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
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
  { "foreign.menu_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-03-20 10:14:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:150ZGyTy+p4YwiRJo0DkaA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
