use utf8;
package Iota::Schema::Result::UserBestPratice;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::UserBestPratice

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

=head1 TABLE: C<user_best_pratice>

=cut

__PACKAGE__->table("user_best_pratice");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'user_best_pratice_id_seq'

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 axis_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 methodology

  data_type: 'text'
  is_nullable: 1

=head2 goals

  data_type: 'text'
  is_nullable: 1

=head2 schedule

  data_type: 'text'
  is_nullable: 1

=head2 results

  data_type: 'text'
  is_nullable: 1

=head2 institutions_involved

  data_type: 'text'
  is_nullable: 1

=head2 contatcts

  data_type: 'text'
  is_nullable: 1

=head2 sources

  data_type: 'text'
  is_nullable: 1

=head2 tags

  data_type: 'text'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 name_url

  data_type: 'text'
  is_nullable: 0

=head2 repercussion

  data_type: 'text'
  is_nullable: 1

=head2 axis_dim1_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 axis_dim2_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 axis_dim3_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 reference_city

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 image_user_file_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 thumbnail_user_file_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 image_caption

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
    sequence          => "user_best_pratice_id_seq",
  },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "axis_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "methodology",
  { data_type => "text", is_nullable => 1 },
  "goals",
  { data_type => "text", is_nullable => 1 },
  "schedule",
  { data_type => "text", is_nullable => 1 },
  "results",
  { data_type => "text", is_nullable => 1 },
  "institutions_involved",
  { data_type => "text", is_nullable => 1 },
  "contatcts",
  { data_type => "text", is_nullable => 1 },
  "sources",
  { data_type => "text", is_nullable => 1 },
  "tags",
  { data_type => "text", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "name_url",
  { data_type => "text", is_nullable => 0 },
  "repercussion",
  { data_type => "text", is_nullable => 1 },
  "axis_dim1_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "axis_dim2_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "axis_dim3_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "reference_city",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "image_user_file_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "thumbnail_user_file_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "image_caption",
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

=head2 axis

Type: belongs_to

Related object: L<Iota::Schema::Result::Axis>

=cut

__PACKAGE__->belongs_to(
  "axis",
  "Iota::Schema::Result::Axis",
  { id => "axis_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 axis_dim1

Type: belongs_to

Related object: L<Iota::Schema::Result::AxisDim1>

=cut

__PACKAGE__->belongs_to(
  "axis_dim1",
  "Iota::Schema::Result::AxisDim1",
  { id => "axis_dim1_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 axis_dim2

Type: belongs_to

Related object: L<Iota::Schema::Result::AxisDim2>

=cut

__PACKAGE__->belongs_to(
  "axis_dim2",
  "Iota::Schema::Result::AxisDim2",
  { id => "axis_dim2_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 axis_dim3

Type: belongs_to

Related object: L<Iota::Schema::Result::AxisDim3>

=cut

__PACKAGE__->belongs_to(
  "axis_dim3",
  "Iota::Schema::Result::AxisDim3",
  { id => "axis_dim3_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

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

=head2 thumbnail_user_file

Type: belongs_to

Related object: L<Iota::Schema::Result::UserFile>

=cut

__PACKAGE__->belongs_to(
  "thumbnail_user_file",
  "Iota::Schema::Result::UserFile",
  { id => "thumbnail_user_file_id" },
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

=head2 user_best_pratice_axes

Type: has_many

Related object: L<Iota::Schema::Result::UserBestPraticeAxis>

=cut

__PACKAGE__->has_many(
  "user_best_pratice_axes",
  "Iota::Schema::Result::UserBestPraticeAxis",
  { "foreign.user_best_pratice_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-08 14:28:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:u6iI/TqEJ4kN36lKnlNVjw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
