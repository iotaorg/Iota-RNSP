use utf8;
package Iota::Schema::Result::Foo;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::Foo

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

=head1 TABLE: C<foo>

=cut

__PACKAGE__->table("foo");

=head1 ACCESSORS

=head2 count

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns("count", { data_type => "bigint", is_nullable => 1 });


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-12-14 17:32:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nWjFxAbcSDUK/9K1IuC4hA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
