use utf8;
package Iota::Schema::Result::EndUserIndicatorQueue;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::EndUserIndicatorQueue

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

=head1 TABLE: C<end_user_indicator_queue>

=cut

__PACKAGE__->table("end_user_indicator_queue");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'end_user_indicator_queue_id_seq'

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 end_user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 email_sent

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 operation_type

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 indicator_id

  data_type: 'integer'
  is_nullable: 0

=head2 valid_from

  data_type: 'date'
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_nullable: 0

=head2 city_id

  data_type: 'integer'
  is_nullable: 1

=head2 institute_id

  data_type: 'integer'
  is_nullable: 0

=head2 region_id

  data_type: 'integer'
  is_nullable: 1

=head2 value

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 variation_name

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 sources

  data_type: 'character varying[]'
  is_nullable: 1

=head2 active_value

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 generated_by_compute

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "end_user_indicator_queue_id_seq",
  },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "end_user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "email_sent",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "operation_type",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "indicator_id",
  { data_type => "integer", is_nullable => 0 },
  "valid_from",
  { data_type => "date", is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_nullable => 0 },
  "city_id",
  { data_type => "integer", is_nullable => 1 },
  "institute_id",
  { data_type => "integer", is_nullable => 0 },
  "region_id",
  { data_type => "integer", is_nullable => 1 },
  "value",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "variation_name",
  {
    data_type     => "text",
    default_value => "",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "sources",
  { data_type => "character varying[]", is_nullable => 1 },
  "active_value",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "generated_by_compute",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 end_user

Type: belongs_to

Related object: L<Iota::Schema::Result::EndUser>

=cut

__PACKAGE__->belongs_to(
  "end_user",
  "Iota::Schema::Result::EndUser",
  { id => "end_user_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2014-07-22 10:07:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Z3zyP8+k3Gcg+MVvZ1sPsg


__PACKAGE__->belongs_to(
  "indicator",
  "Iota::Schema::Result::Indicator",
  { id => "indicator_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


__PACKAGE__->belongs_to(
  "user",
  "Iota::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->belongs_to(
  "region",
  "Iota::Schema::Result::Region",
  { id => "region_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);
# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
