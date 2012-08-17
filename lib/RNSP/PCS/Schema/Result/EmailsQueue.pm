use utf8;
package RNSP::PCS::Schema::Result::EmailsQueue;


use strict;
use warnings;

use base 'DBIx::Class::Core';



__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

=head1 TABLE: C<emails_queue>

=cut

__PACKAGE__->table("emails_queue");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'emails_queue_id_seq'

=head2 to

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 template

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 subject

  data_type: 'varchar'
  is_nullable: 0
  size: 300

=head2 variables

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 sent

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 text_status

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 sent_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "emails_queue_id_seq",
  },
  "to",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "template",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "subject",
  { data_type => "varchar", is_nullable => 0, size => 300 },
  "variables",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "sent",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "text_status",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "sent_at",
  { data_type => "timestamp", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-07-06 11:10:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QrXOns3TKr913F5QEW8vlg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
