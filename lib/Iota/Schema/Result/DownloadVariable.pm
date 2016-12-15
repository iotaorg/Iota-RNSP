use utf8;
package Iota::Schema::Result::DownloadVariable;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::DownloadVariable

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

=head1 TABLE: C<download_variable>

=cut

__PACKAGE__->table("download_variable");
__PACKAGE__->result_source_instance->view_definition(" SELECT c.id AS city_id,\n    c.name AS city_name,\n    v.id AS variable_id,\n    v.type,\n    v.cognomen,\n    (v.period)::character varying AS period,\n    v.source AS exp_source,\n    v.is_basic,\n    m.name AS measurement_unit_name,\n    v.name,\n    vv.valid_from,\n    vv.value,\n    vv.observations,\n    vv.source,\n    vv.user_id,\n    i.id AS institute_id,\n    vv.created_at AS updated_at\n   FROM (((((variable_value vv\n     JOIN variable v ON ((v.id = vv.variable_id)))\n     LEFT JOIN measurement_unit m ON ((m.id = v.measurement_unit_id)))\n     JOIN \"user\" u ON ((u.id = vv.user_id)))\n     JOIN institute i ON ((i.id = u.institute_id)))\n     JOIN city c ON ((c.id = u.city_id)))\nUNION ALL\n SELECT c.id AS city_id,\n    c.name AS city_name,\n    (- vvv.id) AS variable_id,\n    v.type,\n    v.name AS cognomen,\n    ix.period,\n    NULL::text AS exp_source,\n    NULL::boolean AS is_basic,\n    NULL::character varying AS measurement_unit_name,\n    ((vvv.name || ': '::text) || v.name) AS name,\n    vv.valid_from,\n    vv.value,\n    NULL::character varying AS observations,\n    NULL::character varying AS source,\n    vv.user_id,\n    i.id AS institute_id,\n    vv.created_at AS updated_at\n   FROM ((((((indicator_variables_variations_value vv\n     JOIN indicator_variations vvv ON ((vvv.id = vv.indicator_variation_id)))\n     JOIN indicator_variables_variations v ON ((v.id = vv.indicator_variables_variation_id)))\n     JOIN indicator ix ON ((ix.id = vvv.indicator_id)))\n     JOIN \"user\" u ON ((u.id = vv.user_id)))\n     JOIN institute i ON ((i.id = u.institute_id)))\n     JOIN city c ON ((c.id = u.city_id)))\n  WHERE (vv.active_value = true)");

=head1 ACCESSORS

=head2 city_id

  data_type: 'integer'
  is_nullable: 1

=head2 city_name

  data_type: 'text'
  is_nullable: 1

=head2 variable_id

  data_type: 'integer'
  is_nullable: 1

=head2 type

  data_type: 'enum'
  extra: {custom_type_name => "variable_type_enum",list => ["str","int","num"]}
  is_nullable: 1

=head2 cognomen

  data_type: 'text'
  is_nullable: 1

=head2 period

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 exp_source

  data_type: 'text'
  is_nullable: 1

=head2 is_basic

  data_type: 'boolean'
  is_nullable: 1

=head2 measurement_unit_name

  data_type: 'text'
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 valid_from

  data_type: 'date'
  is_nullable: 1

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 observations

  data_type: 'text'
  is_nullable: 1

=head2 source

  data_type: 'text'
  is_nullable: 1

=head2 user_id

  data_type: 'integer'
  is_nullable: 1

=head2 institute_id

  data_type: 'integer'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "city_id",
  { data_type => "integer", is_nullable => 1 },
  "city_name",
  { data_type => "text", is_nullable => 1 },
  "variable_id",
  { data_type => "integer", is_nullable => 1 },
  "type",
  {
    data_type => "enum",
    extra => {
      custom_type_name => "variable_type_enum",
      list => ["str", "int", "num"],
    },
    is_nullable => 1,
  },
  "cognomen",
  { data_type => "text", is_nullable => 1 },
  "period",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "exp_source",
  { data_type => "text", is_nullable => 1 },
  "is_basic",
  { data_type => "boolean", is_nullable => 1 },
  "measurement_unit_name",
  { data_type => "text", is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "valid_from",
  { data_type => "date", is_nullable => 1 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "observations",
  { data_type => "text", is_nullable => 1 },
  "source",
  { data_type => "text", is_nullable => 1 },
  "user_id",
  { data_type => "integer", is_nullable => 1 },
  "institute_id",
  { data_type => "integer", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2016-12-15 15:15:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mbgzD/4xXvoQuYlCOo5LFA

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
