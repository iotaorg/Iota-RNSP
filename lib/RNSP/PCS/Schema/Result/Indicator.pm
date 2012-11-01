use utf8;
package RNSP::PCS::Schema::Result::Indicator;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

RNSP::PCS::Schema::Result::Indicator

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

=head1 TABLE: C<indicator>

=cut

__PACKAGE__->table("indicator");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'indicator_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 formula

  data_type: 'text'
  is_nullable: 0

=head2 goal

  data_type: 'numeric'
  is_nullable: 0

=head2 goal_explanation

  data_type: 'text'
  is_nullable: 1

=head2 goal_source

  data_type: 'text'
  is_nullable: 1

=head2 goal_operator

  data_type: 'text'
  is_nullable: 1

=head2 axis_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 source

  data_type: 'text'
  is_nullable: 1

=head2 explanation

  data_type: 'text'
  is_nullable: 1

=head2 justification_of_missing_field

  data_type: 'text'
  is_nullable: 1

=head2 tags

  data_type: 'text'
  is_nullable: 1

=head2 chart_name

  data_type: 'text'
  is_nullable: 1

=head2 sort_direction

  data_type: 'enum'
  extra: {custom_type_name => "sort_direction_enum",list => ["greater value","greater rating","lowest value","lowest rating"]}
  is_nullable: 1

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 name_url

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
    sequence          => "indicator_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "formula",
  { data_type => "text", is_nullable => 0 },
  "goal",
  { data_type => "numeric", is_nullable => 0 },
  "goal_explanation",
  { data_type => "text", is_nullable => 1 },
  "goal_source",
  { data_type => "text", is_nullable => 1 },
  "goal_operator",
  { data_type => "text", is_nullable => 1 },
  "axis_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "source",
  { data_type => "text", is_nullable => 1 },
  "explanation",
  { data_type => "text", is_nullable => 1 },
  "justification_of_missing_field",
  { data_type => "text", is_nullable => 1 },
  "tags",
  { data_type => "text", is_nullable => 1 },
  "chart_name",
  { data_type => "text", is_nullable => 1 },
  "sort_direction",
  {
    data_type => "enum",
    extra => {
      custom_type_name => "sort_direction_enum",
      list => [
        "greater value",
        "greater rating",
        "lowest value",
        "lowest rating",
      ],
    },
    is_nullable => 1,
  },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "name_url",
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

=head1 UNIQUE CONSTRAINTS

=head2 C<indicator_cognomen_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("indicator_cognomen_key", ["name"]);

=head2 C<indicator_name_url_key>

=over 4

=item * L</name_url>

=back

=cut

__PACKAGE__->add_unique_constraint("indicator_name_url_key", ["name_url"]);

=head1 RELATIONS

=head2 axis

Type: belongs_to

Related object: L<RNSP::PCS::Schema::Result::Axis>

=cut

__PACKAGE__->belongs_to(
  "axis",
  "RNSP::PCS::Schema::Result::Axis",
  { id => "axis_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 user

Type: belongs_to

Related object: L<RNSP::PCS::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "RNSP::PCS::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07028 @ 2012-11-01 15:34:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:H4Ud2Tmod40qI92LlxsTMg

__PACKAGE__->belongs_to(
    "owner",
    "RNSP::PCS::Schema::Result::User",
    { "foreign.id" => "self.user_id" },
    { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
