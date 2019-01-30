use utf8;
package Iota::Schema::Result::DownloadData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::DownloadData

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
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<download_data>

=cut

__PACKAGE__->table("download_data");
__PACKAGE__->result_source_instance->view_definition(" SELECT m.city_id,\n    c.name AS city_name,\n    e.name AS axis_name,\n    m.indicator_id,\n    i.name AS indicator_name,\n    i.formula_human,\n    i.formula,\n    i.goal,\n    i.goal_explanation,\n    i.goal_source,\n    i.goal_operator,\n    i.explanation,\n    i.tags,\n    i.observations,\n    i.period,\n    m.variation_name,\n    iv.\"order\" AS variation_order,\n    m.valid_from,\n    m.value,\n    a.goal AS user_goal,\n    a.justification_of_missing_field,\n    t.technical_information,\n    m.institute_id,\n    m.user_id,\n    m.region_id,\n    m.sources,\n    r.name AS region_name,\n    m.updated_at,\n    m.values_used,\n    d1.name AS axis_aux1,\n    d2.name AS axis_aux2,\n    d3.description AS axis_aux3,\n    ss.uf AS state_uf,\n    ss.name AS state_name,\n    r.depth_level AS region_dl\n   FROM (((((((((((indicator_value m\n     JOIN city c ON ((m.city_id = c.id)))\n     JOIN state ss ON ((c.state_id = ss.id)))\n     JOIN indicator i ON ((i.id = m.indicator_id)))\n     LEFT JOIN axis e ON ((e.id = i.axis_id)))\n     LEFT JOIN axis_dim1 d1 ON ((d1.id = i.axis_dim1_id)))\n     LEFT JOIN axis_dim2 d2 ON ((d2.id = i.axis_dim2_id)))\n     LEFT JOIN axis_dim3 d3 ON ((d3.id = i.axis_dim3_id)))\n     LEFT JOIN indicator_variations iv ON (\n        CASE\n            WHEN (m.variation_name = ''::text) THEN false\n            ELSE ((iv.name = m.variation_name) AND (iv.indicator_id = m.indicator_id) AND ((iv.user_id = m.user_id) OR (iv.user_id = i.user_id)))\n        END))\n     LEFT JOIN user_indicator a ON (((a.user_id = m.user_id) AND (a.valid_from = m.valid_from) AND (a.indicator_id = m.indicator_id))))\n     LEFT JOIN user_indicator_config t ON (((t.user_id = m.user_id) AND (t.indicator_id = i.id))))\n     LEFT JOIN region r ON ((r.id = m.region_id)))");

=head1 ACCESSORS

=head2 city_id

  data_type: 'integer'
  is_nullable: 1

=head2 city_name

  data_type: 'text'
  is_nullable: 1

=head2 axis_name

  data_type: 'text'
  is_nullable: 1

=head2 indicator_id

  data_type: 'integer'
  is_nullable: 1

=head2 indicator_name

  data_type: 'text'
  is_nullable: 1

=head2 formula_human

  data_type: 'text'
  is_nullable: 1

=head2 formula

  data_type: 'text'
  is_nullable: 1

=head2 goal

  data_type: 'numeric'
  is_nullable: 1

=head2 goal_explanation

  data_type: 'text'
  is_nullable: 1

=head2 goal_source

  data_type: 'text'
  is_nullable: 1

=head2 goal_operator

  data_type: 'text'
  is_nullable: 1

=head2 explanation

  data_type: 'text'
  is_nullable: 1

=head2 tags

  data_type: 'text'
  is_nullable: 1

=head2 observations

  data_type: 'text'
  is_nullable: 1

=head2 period

  data_type: 'text'
  is_nullable: 1

=head2 variation_name

  data_type: 'text'
  is_nullable: 1

=head2 variation_order

  data_type: 'integer'
  is_nullable: 1

=head2 valid_from

  data_type: 'date'
  is_nullable: 1

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 user_goal

  data_type: 'text'
  is_nullable: 1

=head2 justification_of_missing_field

  data_type: 'text'
  is_nullable: 1

=head2 technical_information

  data_type: 'text'
  is_nullable: 1

=head2 institute_id

  data_type: 'integer'
  is_nullable: 1

=head2 user_id

  data_type: 'integer'
  is_nullable: 1

=head2 region_id

  data_type: 'integer'
  is_nullable: 1

=head2 sources

  data_type: 'character varying[]'
  is_nullable: 1

=head2 region_name

  data_type: 'text'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 values_used

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 axis_aux1

  data_type: 'text'
  is_nullable: 1

=head2 axis_aux2

  data_type: 'text'
  is_nullable: 1

=head2 axis_aux3

  data_type: 'text'
  is_nullable: 1

=head2 state_uf

  data_type: 'text'
  is_nullable: 1

=head2 state_name

  data_type: 'text'
  is_nullable: 1

=head2 region_dl

  data_type: 'smallint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "city_id",
  { data_type => "integer", is_nullable => 1 },
  "city_name",
  { data_type => "text", is_nullable => 1 },
  "axis_name",
  { data_type => "text", is_nullable => 1 },
  "indicator_id",
  { data_type => "integer", is_nullable => 1 },
  "indicator_name",
  { data_type => "text", is_nullable => 1 },
  "formula_human",
  { data_type => "text", is_nullable => 1 },
  "formula",
  { data_type => "text", is_nullable => 1 },
  "goal",
  { data_type => "numeric", is_nullable => 1 },
  "goal_explanation",
  { data_type => "text", is_nullable => 1 },
  "goal_source",
  { data_type => "text", is_nullable => 1 },
  "goal_operator",
  { data_type => "text", is_nullable => 1 },
  "explanation",
  { data_type => "text", is_nullable => 1 },
  "tags",
  { data_type => "text", is_nullable => 1 },
  "observations",
  { data_type => "text", is_nullable => 1 },
  "period",
  { data_type => "text", is_nullable => 1 },
  "variation_name",
  { data_type => "text", is_nullable => 1 },
  "variation_order",
  { data_type => "integer", is_nullable => 1 },
  "valid_from",
  { data_type => "date", is_nullable => 1 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "user_goal",
  { data_type => "text", is_nullable => 1 },
  "justification_of_missing_field",
  { data_type => "text", is_nullable => 1 },
  "technical_information",
  { data_type => "text", is_nullable => 1 },
  "institute_id",
  { data_type => "integer", is_nullable => 1 },
  "user_id",
  { data_type => "integer", is_nullable => 1 },
  "region_id",
  { data_type => "integer", is_nullable => 1 },
  "sources",
  { data_type => "character varying[]", is_nullable => 1 },
  "region_name",
  { data_type => "text", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "values_used",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "axis_aux1",
  { data_type => "text", is_nullable => 1 },
  "axis_aux2",
  { data_type => "text", is_nullable => 1 },
  "axis_aux3",
  { data_type => "text", is_nullable => 1 },
  "state_uf",
  { data_type => "text", is_nullable => 1 },
  "state_name",
  { data_type => "text", is_nullable => 1 },
  "region_dl",
  { data_type => "smallint", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-01-30 17:40:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vgiJJQmBRiBz7z5ghiPbmA

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
