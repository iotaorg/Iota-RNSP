use utf8;
package Iota::Schema::Result::Foovar;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::Foovar

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

=head1 TABLE: C<foovars>

=cut

__PACKAGE__->table("foovars");

=head1 ACCESSORS

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 explanation

  data_type: 'text'
  is_nullable: 1

=head2 cognomen

  data_type: 'text'
  is_nullable: 1

=head2 user_id

  data_type: 'integer'
  is_nullable: 1

=head2 type

  data_type: 'text'
  is_nullable: 1

=head2 period

  data_type: 'text'
  is_nullable: 1

=head2 source

  data_type: 'text'
  is_nullable: 1

=head2 is_basic

  data_type: 'boolean'
  is_nullable: 1

=head2 measurement_unit_id

  data_type: 'integer'
  is_nullable: 1

=head2 user_type

  data_type: 'text'
  is_nullable: 1

=head2 summarization_method

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "name",
  { data_type => "text", is_nullable => 1 },
  "explanation",
  { data_type => "text", is_nullable => 1 },
  "cognomen",
  { data_type => "text", is_nullable => 1 },
  "user_id",
  { data_type => "integer", is_nullable => 1 },
  "type",
  { data_type => "text", is_nullable => 1 },
  "period",
  { data_type => "text", is_nullable => 1 },
  "source",
  { data_type => "text", is_nullable => 1 },
  "is_basic",
  { data_type => "boolean", is_nullable => 1 },
  "measurement_unit_id",
  { data_type => "integer", is_nullable => 1 },
  "user_type",
  { data_type => "text", is_nullable => 1 },
  "summarization_method",
  { data_type => "text", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-12-14 17:32:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zp8wAB8ORUgrRKRSVuJ3EA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
