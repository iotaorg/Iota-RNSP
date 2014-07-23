use utf8;
package Iota::Schema::Result::EndUser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::EndUser

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

=head1 TABLE: C<end_user>

=cut

__PACKAGE__->table("end_user");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'end_user_id_seq'

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 name

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 email

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 password

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "end_user_id_seq",
  },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "name",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "email",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "password",
  {
    data_type   => "text",
    is_nullable => 0,
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

=head2 end_user_indicator_queues

Type: has_many

Related object: L<Iota::Schema::Result::EndUserIndicatorQueue>

=cut

__PACKAGE__->has_many(
  "end_user_indicator_queues",
  "Iota::Schema::Result::EndUserIndicatorQueue",
  { "foreign.end_user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 end_user_indicator_users

Type: has_many

Related object: L<Iota::Schema::Result::EndUserIndicatorUser>

=cut

__PACKAGE__->has_many(
  "end_user_indicator_users",
  "Iota::Schema::Result::EndUserIndicatorUser",
  { "foreign.end_user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 end_user_indicators

Type: has_many

Related object: L<Iota::Schema::Result::EndUserIndicator>

=cut

__PACKAGE__->has_many(
  "end_user_indicators",
  "Iota::Schema::Result::EndUserIndicator",
  { "foreign.end_user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2014-07-22 09:33:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0hxXbU1+5tq7WTSSmHDFMQ


__PACKAGE__->remove_column('password');
__PACKAGE__->add_column(
    password => {
        data_type        => "text",
        passphrase       => 'crypt',
        passphrase_class => 'BlowfishCrypt',
        passphrase_args  => {
            cost        => 6,
            salt_random => 1,
        },
        passphrase_check_method => 'check_password',
        is_nullable             => 0
    },
);


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
