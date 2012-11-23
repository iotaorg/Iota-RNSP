use utf8;
package RNSP::PCS::Schema::Result::ActionLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

RNSP::PCS::Schema::Result::ActionLog

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

=head1 TABLE: C<actions_log>

=cut

__PACKAGE__->table("actions_log");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'actions_log_id_seq'

=head2 dt_when

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 url

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 user_id

  data_type: 'integer'
  is_nullable: 1

=head2 message

  data_type: 'text'
  is_nullable: 1

=head2 ip

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "actions_log_id_seq",
  },
  "dt_when",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "url",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "user_id",
  { data_type => "integer", is_nullable => 1 },
  "message",
  { data_type => "text", is_nullable => 1 },
  "ip",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-11-23 14:03:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:X729XxKlxrBRn5gK1zDAIg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
