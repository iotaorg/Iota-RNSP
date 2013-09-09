use utf8;
package Iota::Schema::Result::Lexicon;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::Lexicon

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

=head1 TABLE: C<lexicon>

=cut

__PACKAGE__->table("lexicon");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'lexicon_id_seq'

=head2 lang

  data_type: 'varchar'
  default_value: null
  is_nullable: 1
  size: 15

=head2 lex

  data_type: 'varchar'
  default_value: null
  is_nullable: 1
  size: 255

=head2 lex_key

  data_type: 'text'
  is_nullable: 1

=head2 lex_value

  data_type: 'text'
  is_nullable: 1

=head2 notes

  data_type: 'text'
  is_nullable: 1

=head2 user_id

  data_type: 'integer'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 origin_lang

  data_type: 'text'
  default_value: 'pt-br'
  is_nullable: 0
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "lexicon_id_seq",
  },
  "lang",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 15,
  },
  "lex",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 255,
  },
  "lex_key",
  { data_type => "text", is_nullable => 1 },
  "lex_value",
  { data_type => "text", is_nullable => 1 },
  "notes",
  { data_type => "text", is_nullable => 1 },
  "user_id",
  { data_type => "integer", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "origin_lang",
  {
    data_type     => "text",
    default_value => "pt-br",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-09-09 15:46:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cM5iDxpgY9GrFzhCVvZloA

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
