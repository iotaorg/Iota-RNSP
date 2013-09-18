-- Deploy appschema

BEGIN;

CREATE TYPE tp_period_edges AS
(period_name character varying,
period_begin  date,
period_end date);

--
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Wed Sep 18 13:38:54 2013
--
DROP TYPE IF EXISTS tp_visibility_level CASCADE;
CREATE TYPE tp_visibility_level AS ENUM ('public', 'private', 'country', 'restrict');

DROP TYPE IF EXISTS variable_type_enum CASCADE;
CREATE TYPE variable_type_enum AS ENUM ('str', 'int', 'num');

DROP TYPE IF EXISTS period_enum CASCADE;
CREATE TYPE period_enum AS ENUM ('daily', 'weekly', 'monthly', 'bimonthly', 'quarterly', 'semi-annual', 'yearly', 'decade');

DROP TYPE IF EXISTS sort_direction_enum CASCADE;
CREATE TYPE sort_direction_enum AS ENUM ('greater value', 'greater rating', 'lowest value', 'lowest rating');

--
-- Table: axis.
--
CREATE TABLE "axis" (
  "id" serial NOT NULL,
  "name" text NOT NULL,
  "created_at" timestamp DEFAULT current_timestamp NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: country.
--
CREATE TABLE "country" (
  "id" serial NOT NULL,
  "name_url" text,
  "name" text,
  "created_at" timestamp DEFAULT current_timestamp NOT NULL,
  "created_by" integer NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "country_name_uri_key" UNIQUE ("name_url")
);

--
-- Table: download_data.
--
CREATE TABLE "download_data" (
  "city_id" integer,
  "city_name" text,
  "axis_name" text,
  "indicator_id" integer,
  "indicator_name" text,
  "formula_human" text,
  "formula" text,
  "goal" numeric,
  "goal_explanation" text,
  "goal_source" text,
  "goal_operator" text,
  "explanation" text,
  "tags" text,
  "observations" text,
  "period" text,
  "variation_name" text,
  "variation_order" integer,
  "valid_from" date,
  "value" text,
  "user_goal" text,
  "justification_of_missing_field" text,
  "technical_information" text,
  "institute_id" integer,
  "user_id" integer,
  "region_id" integer,
  "sources" character varying[],
  "region_name" text,
  "updated_at" timestamp
);

--
-- Table: download_variable.
--
CREATE TABLE "download_variable" (
  "city_id" integer,
  "city_name" text,
  "variable_id" integer,
  "type" variable_type_enum,
  "cognomen" text,
  "period" text,
  "exp_source" text,
  "is_basic" boolean,
  "measurement_unit_name" text,
  "name" text,
  "valid_from" date,
  "value" text,
  "observations" text,
  "source" text,
  "user_id" integer,
  "institute_id" integer,
  "updated_at" timestamp
);

--
-- Table: emails_queue.
--
CREATE TABLE "emails_queue" (
  "id" serial NOT NULL,
  "to" character varying(100) NOT NULL,
  "template" character varying(100) NOT NULL,
  "subject" character varying(300) NOT NULL,
  "variables" text NOT NULL,
  "sent" boolean DEFAULT false NOT NULL,
  "text_status" text,
  "sent_at" timestamp,
  "created_at" timestamp DEFAULT current_timestamp NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: file.
--
CREATE TABLE "file" (
  "id" serial NOT NULL,
  "name" text,
  "status_text" text,
  "created_at" timestamp DEFAULT current_timestamp,
  "created_by" integer NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: institute.
--
CREATE TABLE "institute" (
  "id" serial NOT NULL,
  "name" text NOT NULL,
  "short_name" text NOT NULL,
  "description" text,
  "created_at" timestamp DEFAULT current_timestamp NOT NULL,
  "users_can_edit_value" boolean DEFAULT false NOT NULL,
  "users_can_edit_groups" boolean DEFAULT false NOT NULL,
  "can_use_custom_css" boolean DEFAULT false NOT NULL,
  "can_use_custom_pages" boolean DEFAULT false NOT NULL,
  "bypass_indicator_axis_if_custom" boolean DEFAULT true NOT NULL,
  "hide_empty_indicators" boolean DEFAULT false NOT NULL,
  "license" text,
  "license_url" text,
  "image_url" text,
  "datapackage_autor" text,
  "datapackage_autor_email" text,
  PRIMARY KEY ("id"),
  CONSTRAINT "institute_short_name_key" UNIQUE ("short_name")
);

--
-- Table: lexicon.
--
CREATE TABLE "lexicon" (
  "id" serial NOT NULL,
  "lang" character varying(15) DEFAULT null,
  "lex" character varying(255) DEFAULT null,
  "lex_key" text,
  "lex_value" text,
  "notes" text,
  "user_id" integer,
  "created_at" timestamp DEFAULT current_timestamp NOT NULL,
  "origin_lang" text DEFAULT 'pt-br' NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: measurement_unit.
--
CREATE TABLE "measurement_unit" (
  "id" serial NOT NULL,
  "name" text,
  "short_name" text,
  "user_id" integer NOT NULL,
  "created_at" timestamp DEFAULT current_timestamp,
  PRIMARY KEY ("id")
);

--
-- Table: role.
--
CREATE TABLE "role" (
  "id" serial NOT NULL,
  "name" text NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "role_name_key" UNIQUE ("name")
);

--
-- Table: user_file.
--
CREATE TABLE "user_file" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "class_name" text DEFAULT 'perfil' NOT NULL,
  "public_url" text NOT NULL,
  "private_path" text NOT NULL,
  "created_at" timestamp DEFAULT current_timestamp NOT NULL,
  "hide_listing" boolean DEFAULT true NOT NULL,
  "description" text,
  "public_name" text,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_file_idx_user_id" on "user_file" ("user_id");

--
-- Table: user_forgotten_passwords.
--
CREATE TABLE "user_forgotten_passwords" (
  "id" serial NOT NULL,
  "id_user" integer NOT NULL,
  "secret_key" character varying(100) NOT NULL,
  "created_at" timestamp DEFAULT current_timestamp,
  "valid_until" timestamp DEFAULT (now() + '30 days'::interval),
  "reseted_at" timestamp,
  PRIMARY KEY ("id"),
  CONSTRAINT "user_forgotten_passwords_secret_key_key" UNIQUE ("secret_key")
);
CREATE INDEX "user_forgotten_passwords_idx_id_user" on "user_forgotten_passwords" ("id_user");

--
-- Table: user_role.
--
CREATE TABLE "user_role" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "role_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_role_idx_role_id" on "user_role" ("role_id");
CREATE INDEX "user_role_idx_user_id" on "user_role" ("user_id");

--
-- Table: user_session.
--
CREATE TABLE "user_session" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "api_key" text,
  "valid_for_ip" text,
  "valid_until" timestamp DEFAULT (now() + '1 day'::interval) NOT NULL,
  "ts_created" timestamp DEFAULT current_timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "user_session_api_key_key" UNIQUE ("api_key")
);
CREATE INDEX "user_session_idx_user_id" on "user_session" ("user_id");

--
-- Table: network.
--
CREATE TABLE "network" (
  "id" serial NOT NULL,
  "name" text NOT NULL,
  "name_url" text NOT NULL,
  "created_at" timestamp DEFAULT current_timestamp NOT NULL,
  "created_by" integer NOT NULL,
  "institute_id" integer NOT NULL,
  "domain_name" character varying(100) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "network_domain_name_key" UNIQUE ("domain_name"),
  CONSTRAINT "network_name_url_key" UNIQUE ("name_url")
);
CREATE INDEX "network_idx_institute_id" on "network" ("institute_id");

--
-- Table: state.
--
CREATE TABLE "state" (
  "id" serial NOT NULL,
  "name_url" text,
  "name" text,
  "created_at" timestamp DEFAULT current_timestamp NOT NULL,
  "created_by" integer NOT NULL,
  "country_id" integer,
  "uf" text NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "state_name_uri_key" UNIQUE ("name_url")
);
CREATE INDEX "state_idx_country_id" on "state" ("country_id");

--
-- Table: user.
--
CREATE TABLE "user" (
  "id" serial NOT NULL,
  "name" text NOT NULL,
  "email" text NOT NULL,
  "city_id" integer,
  "api_key" text,
  "nome_responsavel_cadastro" text,
  "estado" text,
  "telefone" text,
  "email_contato" text,
  "telefone_contato" text,
  "cidade" text,
  "bairro" text,
  "cep" text,
  "endereco" text,
  "city_summary" text,
  "active" boolean DEFAULT true NOT NULL,
  "created_at" timestamp DEFAULT current_timestamp NOT NULL,
  "institute_id" integer,
  "cur_lang" text DEFAULT 'pt-br' NOT NULL,
  "password" text NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "user_email_key" UNIQUE ("email")
);
CREATE INDEX "user_idx_city_id" on "user" ("city_id");
CREATE INDEX "user_idx_institute_id" on "user" ("institute_id");

--
-- Table: actions_log.
--
CREATE TABLE "actions_log" (
  "id" serial NOT NULL,
  "dt_when" timestamp DEFAULT current_timestamp NOT NULL,
  "url" text,
  "user_id" integer,
  "message" text,
  "ip" text,
  "indicator_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "actions_log_idx_user_id" on "actions_log" ("user_id");

--
-- Table: city.
--
CREATE TABLE "city" (
  "id" serial NOT NULL,
  "name" text NOT NULL,
  "uf" character(2) NOT NULL,
  "pais" text DEFAULT 'br',
  "latitude" double precision,
  "longitude" double precision,
  "created_at" timestamp DEFAULT current_timestamp NOT NULL,
  "name_uri" text,
  "telefone_prefeitura" text,
  "endereco_prefeitura" text,
  "bairro_prefeitura" text,
  "cep_prefeitura" text,
  "email_prefeitura" text,
  "nome_responsavel_prefeitura" text,
  "summary" text,
  "state_id" integer,
  "country_id" integer,
  "automatic_fill" boolean DEFAULT false NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "city_pais_uf_name_uri_key" UNIQUE ("pais", "uf", "name_uri")
);
CREATE INDEX "city_idx_country_id" on "city" ("country_id");
CREATE INDEX "city_idx_state_id" on "city" ("state_id");

--
-- Table: source.
--
CREATE TABLE "source" (
  "id" serial NOT NULL,
  "name" text NOT NULL,
  "user_id" integer NOT NULL,
  "created_at" timestamp DEFAULT current_timestamp,
  PRIMARY KEY ("id")
);
CREATE INDEX "source_idx_user_id" on "source" ("user_id");

--
-- Table: user_best_pratice.
--
CREATE TABLE "user_best_pratice" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "axis_id" integer NOT NULL,
  "name" text NOT NULL,
  "description" text,
  "methodology" text,
  "goals" text,
  "schedule" text,
  "results" text,
  "institutions_involved" text,
  "contatcts" text,
  "sources" text,
  "tags" text,
  "created_at" timestamp DEFAULT current_timestamp NOT NULL,
  "name_url" text NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_best_pratice_idx_axis_id" on "user_best_pratice" ("axis_id");
CREATE INDEX "user_best_pratice_idx_user_id" on "user_best_pratice" ("user_id");

--
-- Table: user_indicator_axis.
--
CREATE TABLE "user_indicator_axis" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "name" text NOT NULL,
  "position" integer DEFAULT 0 NOT NULL,
  "created_at" timestamp DEFAULT current_timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_indicator_axis_idx_user_id" on "user_indicator_axis" ("user_id");

--
-- Table: user_page.
--
CREATE TABLE "user_page" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "created_at" timestamp DEFAULT current_timestamp NOT NULL,
  "published_at" timestamp DEFAULT current_timestamp,
  "title" text NOT NULL,
  "title_url" text NOT NULL,
  "content" text NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_page_idx_user_id" on "user_page" ("user_id");

--
-- Table: user_region.
--
CREATE TABLE "user_region" (
  "id" serial NOT NULL,
  "depth_level" smallint DEFAULT 2 NOT NULL,
  "user_id" integer NOT NULL,
  "region_classification_name" text NOT NULL,
  "created_at" timestamp DEFAULT current_timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_region_idx_user_id" on "user_region" ("user_id");

--
-- Table: indicator.
--
CREATE TABLE "indicator" (
  "id" serial NOT NULL,
  "name" text NOT NULL,
  "formula" text NOT NULL,
  "goal" numeric,
  "goal_explanation" text,
  "goal_source" text,
  "goal_operator" text,
  "axis_id" integer NOT NULL,
  "source" text,
  "explanation" text,
  "tags" text,
  "chart_name" text,
  "sort_direction" sort_direction_enum,
  "user_id" integer NOT NULL,
  "created_at" timestamp DEFAULT current_timestamp,
  "name_url" text,
  "observations" text,
  "variety_name" text,
  "indicator_type" text DEFAULT 'normal' NOT NULL,
  "all_variations_variables_are_required" boolean DEFAULT true NOT NULL,
  "summarization_method" text DEFAULT 'sum' NOT NULL,
  "indicator_admins" text,
  "dynamic_variations" boolean,
  "visibility_level" tp_visibility_level,
  "visibility_user_id" integer,
  "visibility_country_id" integer,
  "formula_human" text,
  "period" text,
  "variable_type" text,
  "featured_in_home" boolean DEFAULT false NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "indicator_cognomen_key" UNIQUE ("name"),
  CONSTRAINT "indicator_name_url_key2" UNIQUE ("name_url")
);
CREATE INDEX "indicator_idx_axis_id" on "indicator" ("axis_id");
CREATE INDEX "indicator_idx_user_id" on "indicator" ("user_id");
CREATE INDEX "indicator_idx_visibility_country_id" on "indicator" ("visibility_country_id");
CREATE INDEX "indicator_idx_visibility_user_id" on "indicator" ("visibility_user_id");

--
-- Table: network_user.
--
CREATE TABLE "network_user" (
  "network_id" integer NOT NULL,
  "user_id" integer NOT NULL,
  PRIMARY KEY ("user_id", "network_id")
);
CREATE INDEX "network_user_idx_network_id" on "network_user" ("network_id");
CREATE INDEX "network_user_idx_user_id" on "network_user" ("user_id");

--
-- Table: user_indicator_axis_item.
--
CREATE TABLE "user_indicator_axis_item" (
  "id" serial NOT NULL,
  "user_indicator_axis_id" integer NOT NULL,
  "indicator_id" integer NOT NULL,
  "position" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "user_indicator_axis_item_user_indicator_axis_id_indicator_i_key" UNIQUE ("user_indicator_axis_id", "indicator_id")
);
CREATE INDEX "user_indicator_axis_item_idx_user_indicator_axis_id" on "user_indicator_axis_item" ("user_indicator_axis_id");

--
-- Table: user_menu.
--
CREATE TABLE "user_menu" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "page_id" integer,
  "title" text NOT NULL,
  "position" integer DEFAULT 0 NOT NULL,
  "menu_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_menu_idx_menu_id" on "user_menu" ("menu_id");
CREATE INDEX "user_menu_idx_page_id" on "user_menu" ("page_id");
CREATE INDEX "user_menu_idx_user_id" on "user_menu" ("user_id");

--
-- Table: variable.
--
CREATE TABLE "variable" (
  "id" serial NOT NULL,
  "name" text NOT NULL,
  "explanation" text NOT NULL,
  "cognomen" text NOT NULL,
  "user_id" integer NOT NULL,
  "created_at" timestamp DEFAULT current_timestamp,
  "type" variable_type_enum DEFAULT 'str' NOT NULL,
  "period" period_enum NOT NULL,
  "source" text,
  "is_basic" boolean DEFAULT false,
  "measurement_unit_id" integer,
  PRIMARY KEY ("id"),
  CONSTRAINT "variable_cognomen_key" UNIQUE ("cognomen")
);
CREATE INDEX "variable_idx_measurement_unit_id" on "variable" ("measurement_unit_id");
CREATE INDEX "variable_idx_user_id" on "variable" ("user_id");

--
-- Table: indicator_user_visibility.
--
CREATE TABLE "indicator_user_visibility" (
  "id" serial NOT NULL,
  "indicator_id" integer,
  "user_id" integer,
  "created_at" timestamp DEFAULT current_timestamp NOT NULL,
  "created_by" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "indicator_user_visibility_idx_created_by" on "indicator_user_visibility" ("created_by");
CREATE INDEX "indicator_user_visibility_idx_indicator_id" on "indicator_user_visibility" ("indicator_id");
CREATE INDEX "indicator_user_visibility_idx_user_id" on "indicator_user_visibility" ("user_id");

--
-- Table: indicator_variables_variations.
--
CREATE TABLE "indicator_variables_variations" (
  "id" serial NOT NULL,
  "indicator_id" integer NOT NULL,
  "name" text NOT NULL,
  "type" variable_type_enum DEFAULT 'int' NOT NULL,
  "explanation" text,
  "created_at" timestamp DEFAULT current_timestamp,
  PRIMARY KEY ("id")
);
CREATE INDEX "indicator_variables_variations_idx_indicator_id" on "indicator_variables_variations" ("indicator_id");

--
-- Table: indicator_variations.
--
CREATE TABLE "indicator_variations" (
  "id" serial NOT NULL,
  "indicator_id" integer NOT NULL,
  "name" text NOT NULL,
  "created_at" timestamp DEFAULT current_timestamp,
  "order" integer DEFAULT 0 NOT NULL,
  "user_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "indicator_variations_idx_indicator_id" on "indicator_variations" ("indicator_id");
CREATE INDEX "indicator_variations_idx_user_id" on "indicator_variations" ("user_id");

--
-- Table: user_best_pratice_axis.
--
CREATE TABLE "user_best_pratice_axis" (
  "id" serial NOT NULL,
  "axis_id" integer NOT NULL,
  "user_best_pratice_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_best_pratice_axis_idx_axis_id" on "user_best_pratice_axis" ("axis_id");
CREATE INDEX "user_best_pratice_axis_idx_user_best_pratice_id" on "user_best_pratice_axis" ("user_best_pratice_id");

--
-- Table: user_indicator_config.
--
CREATE TABLE "user_indicator_config" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "indicator_id" integer NOT NULL,
  "technical_information" text,
  "created_at" timestamp DEFAULT current_timestamp,
  "hide_indicator" boolean DEFAULT false NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "user_indicator_config_user_id_indicator_id_key" UNIQUE ("user_id", "indicator_id")
);
CREATE INDEX "user_indicator_config_idx_indicator_id" on "user_indicator_config" ("indicator_id");
CREATE INDEX "user_indicator_config_idx_user_id" on "user_indicator_config" ("user_id");

--
-- Table: user_variable_config.
--
CREATE TABLE "user_variable_config" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "variable_id" integer NOT NULL,
  "display_in_home" boolean DEFAULT true NOT NULL,
  "created_at" timestamp DEFAULT current_timestamp,
  "position" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "user_variable_config_user_id_variable_id_key" UNIQUE ("user_id", "variable_id")
);
CREATE INDEX "user_variable_config_idx_user_id" on "user_variable_config" ("user_id");
CREATE INDEX "user_variable_config_idx_variable_id" on "user_variable_config" ("variable_id");

--
-- Table: city_current_user.
--
CREATE TABLE "city_current_user" (
  "city_id" integer NOT NULL,
  "user_id" integer NOT NULL,
  PRIMARY KEY ("user_id", "city_id")
);
CREATE INDEX "city_current_user_idx_city_id" on "city_current_user" ("city_id");
CREATE INDEX "city_current_user_idx_user_id" on "city_current_user" ("user_id");

--
-- Table: indicator_network_config.
--
CREATE TABLE "indicator_network_config" (
  "indicator_id" integer NOT NULL,
  "network_id" integer NOT NULL,
  "unfolded_in_home" boolean DEFAULT false NOT NULL,
  PRIMARY KEY ("indicator_id", "network_id")
);
CREATE INDEX "indicator_network_config_idx_indicator_id" on "indicator_network_config" ("indicator_id");
CREATE INDEX "indicator_network_config_idx_network_id" on "indicator_network_config" ("network_id");

--
-- Table: region.
--
CREATE TABLE "region" (
  "id" serial NOT NULL,
  "name" text NOT NULL,
  "name_url" text NOT NULL,
  "description" text,
  "city_id" integer NOT NULL,
  "upper_region" integer,
  "depth_level" smallint DEFAULT 2 NOT NULL,
  "created_at" timestamp DEFAULT current_timestamp NOT NULL,
  "created_by" integer NOT NULL,
  "automatic_fill" boolean DEFAULT false NOT NULL,
  "polygon_path" text,
  "subregions_valid_after" timestamp,
  PRIMARY KEY ("id")
);
CREATE INDEX "region_idx_city_id" on "region" ("city_id");
CREATE INDEX "region_idx_created_by" on "region" ("created_by");
CREATE INDEX "region_idx_upper_region" on "region" ("upper_region");

--
-- Table: variable_value.
--
CREATE TABLE "variable_value" (
  "id" serial NOT NULL,
  "value" text,
  "variable_id" integer NOT NULL,
  "user_id" integer NOT NULL,
  "created_at" timestamp DEFAULT current_timestamp,
  "value_of_date" timestamp,
  "valid_from" date NOT NULL,
  "valid_until" date,
  "observations" text,
  "source" text,
  "file_id" integer,
  "cloned_from_user" integer,
  PRIMARY KEY ("id"),
  CONSTRAINT "user_value_period_key" UNIQUE ("variable_id", "user_id", "valid_from")
);
CREATE INDEX "variable_value_idx_cloned_from_user" on "variable_value" ("cloned_from_user");
CREATE INDEX "variable_value_idx_file_id" on "variable_value" ("file_id");
CREATE INDEX "variable_value_idx_user_id" on "variable_value" ("user_id");
CREATE INDEX "variable_value_idx_variable_id" on "variable_value" ("variable_id");

--
-- Table: indicator_variable.
--
CREATE TABLE "indicator_variable" (
  "id" serial NOT NULL,
  "indicator_id" integer NOT NULL,
  "variable_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "indicator_variable_idx_indicator_id" on "indicator_variable" ("indicator_id");
CREATE INDEX "indicator_variable_idx_variable_id" on "indicator_variable" ("variable_id");

--
-- Table: user_indicator.
--
CREATE TABLE "user_indicator" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "indicator_id" integer NOT NULL,
  "valid_from" date NOT NULL,
  "goal" text,
  "justification_of_missing_field" text,
  "created_at" timestamp DEFAULT current_timestamp,
  "region_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_indicator_idx_indicator_id" on "user_indicator" ("indicator_id");
CREATE INDEX "user_indicator_idx_region_id" on "user_indicator" ("region_id");
CREATE INDEX "user_indicator_idx_user_id" on "user_indicator" ("user_id");

--
-- Table: indicator_value.
--
CREATE TABLE "indicator_value" (
  "id" serial NOT NULL,
  "indicator_id" integer NOT NULL,
  "valid_from" date NOT NULL,
  "user_id" integer NOT NULL,
  "city_id" integer,
  "institute_id" integer NOT NULL,
  "region_id" integer,
  "value" text NOT NULL,
  "variation_name" text DEFAULT '' NOT NULL,
  "updated_at" timestamp DEFAULT current_timestamp NOT NULL,
  "sources" character varying[],
  "active_value" boolean DEFAULT true NOT NULL,
  "generated_by_compute" boolean DEFAULT false NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "indicator_value_idx_city_id" on "indicator_value" ("city_id");
CREATE INDEX "indicator_value_idx_indicator_id" on "indicator_value" ("indicator_id");
CREATE INDEX "indicator_value_idx_institute_id" on "indicator_value" ("institute_id");
CREATE INDEX "indicator_value_idx_region_id" on "indicator_value" ("region_id");
CREATE INDEX "indicator_value_idx_user_id" on "indicator_value" ("user_id");

--
-- Table: region_variable_value.
--
CREATE TABLE "region_variable_value" (
  "id" serial NOT NULL,
  "region_id" integer NOT NULL,
  "variable_id" integer NOT NULL,
  "value" text,
  "user_id" integer NOT NULL,
  "created_at" timestamp DEFAULT current_timestamp,
  "value_of_date" timestamp,
  "valid_from" date NOT NULL,
  "valid_until" date,
  "observations" text,
  "source" text,
  "file_id" integer,
  "generated_by_compute" boolean,
  "active_value" boolean DEFAULT true NOT NULL,
  "cloned_from_user" integer,
  PRIMARY KEY ("id"),
  CONSTRAINT "region_variable_value_region_id_variable_id_user_id_valid_f_key" UNIQUE ("region_id", "variable_id", "user_id", "valid_from", "active_value")
);
CREATE INDEX "region_variable_value_idx_cloned_from_user" on "region_variable_value" ("cloned_from_user");
CREATE INDEX "region_variable_value_idx_user_id" on "region_variable_value" ("user_id");
CREATE INDEX "region_variable_value_idx_region_id" on "region_variable_value" ("region_id");
CREATE INDEX "region_variable_value_idx_variable_id" on "region_variable_value" ("variable_id");

--
-- Table: user_variable_region_config.
--
CREATE TABLE "user_variable_region_config" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "region_id" integer NOT NULL,
  "variable_id" integer NOT NULL,
  "display_in_home" boolean DEFAULT true NOT NULL,
  "created_at" timestamp DEFAULT current_timestamp,
  "position" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "user_variable_region_config_user_id_region_id_variable_id_key" UNIQUE ("user_id", "region_id", "variable_id")
);
CREATE INDEX "user_variable_region_config_idx_region_id" on "user_variable_region_config" ("region_id");
CREATE INDEX "user_variable_region_config_idx_user_id" on "user_variable_region_config" ("user_id");
CREATE INDEX "user_variable_region_config_idx_variable_id" on "user_variable_region_config" ("variable_id");

--
-- Table: indicator_variables_variations_value.
--
CREATE TABLE "indicator_variables_variations_value" (
  "id" serial NOT NULL,
  "indicator_variation_id" integer NOT NULL,
  "indicator_variables_variation_id" integer NOT NULL,
  "value" text,
  "value_of_date" timestamp,
  "valid_from" date NOT NULL,
  "valid_until" date,
  "user_id" integer NOT NULL,
  "created_at" timestamp DEFAULT current_timestamp,
  "region_id" integer,
  "generated_by_compute" boolean,
  "active_value" boolean DEFAULT true NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "indicator_variables_variations_value_idx_indicator_variables_variation_id" on "indicator_variables_variations_value" ("indicator_variables_variation_id");
CREATE INDEX "indicator_variables_variations_value_idx_indicator_variation_id" on "indicator_variables_variations_value" ("indicator_variation_id");
CREATE INDEX "indicator_variables_variations_value_idx_region_id" on "indicator_variables_variations_value" ("region_id");

--
-- Foreign Key Definitions
--

ALTER TABLE "user_file" ADD CONSTRAINT "user_file_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "user_forgotten_passwords" ADD CONSTRAINT "user_forgotten_passwords_fk_id_user" FOREIGN KEY ("id_user")
  REFERENCES "user" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "user_role" ADD CONSTRAINT "user_role_fk_role_id" FOREIGN KEY ("role_id")
  REFERENCES "role" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "user_role" ADD CONSTRAINT "user_role_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "user_session" ADD CONSTRAINT "user_session_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "network" ADD CONSTRAINT "network_fk_institute_id" FOREIGN KEY ("institute_id")
  REFERENCES "institute" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "state" ADD CONSTRAINT "state_fk_country_id" FOREIGN KEY ("country_id")
  REFERENCES "country" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user" ADD CONSTRAINT "user_fk_city_id" FOREIGN KEY ("city_id")
  REFERENCES "city" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "user" ADD CONSTRAINT "user_fk_institute_id" FOREIGN KEY ("institute_id")
  REFERENCES "institute" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "actions_log" ADD CONSTRAINT "actions_log_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "city" ADD CONSTRAINT "city_fk_country_id" FOREIGN KEY ("country_id")
  REFERENCES "country" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "city" ADD CONSTRAINT "city_fk_state_id" FOREIGN KEY ("state_id")
  REFERENCES "state" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "source" ADD CONSTRAINT "source_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user_best_pratice" ADD CONSTRAINT "user_best_pratice_fk_axis_id" FOREIGN KEY ("axis_id")
  REFERENCES "axis" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

ALTER TABLE "user_best_pratice" ADD CONSTRAINT "user_best_pratice_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user_indicator_axis" ADD CONSTRAINT "user_indicator_axis_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user_page" ADD CONSTRAINT "user_page_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user_region" ADD CONSTRAINT "user_region_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "indicator" ADD CONSTRAINT "indicator_fk_axis_id" FOREIGN KEY ("axis_id")
  REFERENCES "axis" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "indicator" ADD CONSTRAINT "indicator_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "indicator" ADD CONSTRAINT "indicator_fk_visibility_country_id" FOREIGN KEY ("visibility_country_id")
  REFERENCES "country" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "indicator" ADD CONSTRAINT "indicator_fk_visibility_user_id" FOREIGN KEY ("visibility_user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "network_user" ADD CONSTRAINT "network_user_fk_network_id" FOREIGN KEY ("network_id")
  REFERENCES "network" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "network_user" ADD CONSTRAINT "network_user_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user_indicator_axis_item" ADD CONSTRAINT "user_indicator_axis_item_fk_user_indicator_axis_id" FOREIGN KEY ("user_indicator_axis_id")
  REFERENCES "user_indicator_axis" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user_menu" ADD CONSTRAINT "user_menu_fk_menu_id" FOREIGN KEY ("menu_id")
  REFERENCES "user_menu" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user_menu" ADD CONSTRAINT "user_menu_fk_page_id" FOREIGN KEY ("page_id")
  REFERENCES "user_page" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user_menu" ADD CONSTRAINT "user_menu_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "variable" ADD CONSTRAINT "variable_fk_measurement_unit_id" FOREIGN KEY ("measurement_unit_id")
  REFERENCES "measurement_unit" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "variable" ADD CONSTRAINT "variable_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "indicator_user_visibility" ADD CONSTRAINT "indicator_user_visibility_fk_created_by" FOREIGN KEY ("created_by")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "indicator_user_visibility" ADD CONSTRAINT "indicator_user_visibility_fk_indicator_id" FOREIGN KEY ("indicator_id")
  REFERENCES "indicator" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "indicator_user_visibility" ADD CONSTRAINT "indicator_user_visibility_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "indicator_variables_variations" ADD CONSTRAINT "indicator_variables_variations_fk_indicator_id" FOREIGN KEY ("indicator_id")
  REFERENCES "indicator" ("id") ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE "indicator_variations" ADD CONSTRAINT "indicator_variations_fk_indicator_id" FOREIGN KEY ("indicator_id")
  REFERENCES "indicator" ("id") ON DELETE NO ACTION ON UPDATE RESTRICT;

ALTER TABLE "indicator_variations" ADD CONSTRAINT "indicator_variations_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user_best_pratice_axis" ADD CONSTRAINT "user_best_pratice_axis_fk_axis_id" FOREIGN KEY ("axis_id")
  REFERENCES "axis" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user_best_pratice_axis" ADD CONSTRAINT "user_best_pratice_axis_fk_user_best_pratice_id" FOREIGN KEY ("user_best_pratice_id")
  REFERENCES "user_best_pratice" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user_indicator_config" ADD CONSTRAINT "user_indicator_config_fk_indicator_id" FOREIGN KEY ("indicator_id")
  REFERENCES "indicator" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user_indicator_config" ADD CONSTRAINT "user_indicator_config_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user_variable_config" ADD CONSTRAINT "user_variable_config_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user_variable_config" ADD CONSTRAINT "user_variable_config_fk_variable_id" FOREIGN KEY ("variable_id")
  REFERENCES "variable" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "city_current_user" ADD CONSTRAINT "city_current_user_fk_city_id" FOREIGN KEY ("city_id")
  REFERENCES "city" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "city_current_user" ADD CONSTRAINT "city_current_user_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") DEFERRABLE;

ALTER TABLE "indicator_network_config" ADD CONSTRAINT "indicator_network_config_fk_indicator_id" FOREIGN KEY ("indicator_id")
  REFERENCES "indicator" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "indicator_network_config" ADD CONSTRAINT "indicator_network_config_fk_network_id" FOREIGN KEY ("network_id")
  REFERENCES "network" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "region" ADD CONSTRAINT "region_fk_city_id" FOREIGN KEY ("city_id")
  REFERENCES "city" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "region" ADD CONSTRAINT "region_fk_created_by" FOREIGN KEY ("created_by")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "region" ADD CONSTRAINT "region_fk_upper_region" FOREIGN KEY ("upper_region")
  REFERENCES "region" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "variable_value" ADD CONSTRAINT "variable_value_fk_cloned_from_user" FOREIGN KEY ("cloned_from_user")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "variable_value" ADD CONSTRAINT "variable_value_fk_file_id" FOREIGN KEY ("file_id")
  REFERENCES "file" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "variable_value" ADD CONSTRAINT "variable_value_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "variable_value" ADD CONSTRAINT "variable_value_fk_variable_id" FOREIGN KEY ("variable_id")
  REFERENCES "variable" ("id") ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE "indicator_variable" ADD CONSTRAINT "indicator_variable_fk_indicator_id" FOREIGN KEY ("indicator_id")
  REFERENCES "indicator" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "indicator_variable" ADD CONSTRAINT "indicator_variable_fk_variable_id" FOREIGN KEY ("variable_id")
  REFERENCES "variable" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user_indicator" ADD CONSTRAINT "user_indicator_fk_indicator_id" FOREIGN KEY ("indicator_id")
  REFERENCES "indicator" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "user_indicator" ADD CONSTRAINT "user_indicator_fk_region_id" FOREIGN KEY ("region_id")
  REFERENCES "region" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user_indicator" ADD CONSTRAINT "user_indicator_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "indicator_value" ADD CONSTRAINT "indicator_value_fk_city_id" FOREIGN KEY ("city_id")
  REFERENCES "city" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "indicator_value" ADD CONSTRAINT "indicator_value_fk_indicator_id" FOREIGN KEY ("indicator_id")
  REFERENCES "indicator" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "indicator_value" ADD CONSTRAINT "indicator_value_fk_institute_id" FOREIGN KEY ("institute_id")
  REFERENCES "institute" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "indicator_value" ADD CONSTRAINT "indicator_value_fk_region_id" FOREIGN KEY ("region_id")
  REFERENCES "region" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "indicator_value" ADD CONSTRAINT "indicator_value_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "region_variable_value" ADD CONSTRAINT "region_variable_value_fk_cloned_from_user" FOREIGN KEY ("cloned_from_user")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "region_variable_value" ADD CONSTRAINT "region_variable_value_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "region_variable_value" ADD CONSTRAINT "region_variable_value_fk_region_id" FOREIGN KEY ("region_id")
  REFERENCES "region" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "region_variable_value" ADD CONSTRAINT "region_variable_value_fk_variable_id" FOREIGN KEY ("variable_id")
  REFERENCES "variable" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user_variable_region_config" ADD CONSTRAINT "user_variable_region_config_fk_region_id" FOREIGN KEY ("region_id")
  REFERENCES "region" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user_variable_region_config" ADD CONSTRAINT "user_variable_region_config_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "user_variable_region_config" ADD CONSTRAINT "user_variable_region_config_fk_variable_id" FOREIGN KEY ("variable_id")
  REFERENCES "variable" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "indicator_variables_variations_value" ADD CONSTRAINT "indicator_variables_variations_value_fk_indicator_variables_variation_id" FOREIGN KEY ("indicator_variables_variation_id")
  REFERENCES "indicator_variables_variations" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "indicator_variables_variations_value" ADD CONSTRAINT "indicator_variables_variations_value_fk_indicator_variation_id" FOREIGN KEY ("indicator_variation_id")
  REFERENCES "indicator_variations" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "indicator_variables_variations_value" ADD CONSTRAINT "indicator_variables_variations_value_fk_region_id" FOREIGN KEY ("region_id")
  REFERENCES "region" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

SELECT setval('city_id_seq', 30, true);
SELECT setval('axis_id_seq', 100, true);
SELECT setval('institute_id_seq', 10, true);
SELECT setval('variable_id_seq', 40, true);
SELECT setval('network_id_seq', 10, true);
SELECT setval('user_id_seq', 10, true);
SELECT setval('role_id_seq', 10, true);
SELECT setval('country_id_seq', 10, true);
SELECT setval('state_id_seq', 10, true);


create unique index ix_indicator_value__value_unique ON indicator_value(indicator_id, valid_from,user_id,variation_name,active_value) where region_id is null;
create unique index ix_indicator_value__value_unique_region ON indicator_value(indicator_id, valid_from,user_id,variation_name,active_value,region_id) where region_id is null;


create unique index ix_indicator_variables_variations_value ON indicator_variables_variations_value(
indicator_variation_id,
indicator_variables_variation_id,
valid_from,
user_id,
active_value
) where region_id is null;


create unique index ix_indicator_variables_variations_value_region ON indicator_variables_variations_value(
indicator_variation_id,
indicator_variables_variation_id,
valid_from,
user_id,
active_value,
region_id
) where region_id is not null;

create unique index ix_region_variable_value on region_variable_value (
variable_id,
user_id,
valid_from,
active_value
) where region_id is null;

create unique index ix_region_variable_value_region  on region_variable_value(
variable_id,
user_id,
valid_from,
active_value,
region_id
) where region_id is not null;

create unique index ix_variable_value on variable_value(
variable_id,
user_id,
valid_from
);



-- all passwords are 12345

INSERT INTO "role"(id,name) VALUES (0,'superadmin'), (1,'admin'),(2,'user');

INSERT INTO "user"(id, name, email, password) VALUES (1, 'superadmin','superadmin@email.com', '$2a$08$Hys9hzza605zZVKNJvdiBe9bHfdB4JKFnG8douGv53IW4e9M5cKrW');


INSERT INTO country(
        id, name, name_url, created_by)
VALUES (1, 'Brasil','br',1);


INSERT INTO state(
        id, name, name_url, country_id, uf, created_by)
VALUES (1, 'São Paulo','sao-paulo',1,'SP',1);

INSERT INTO state(
        id, name, name_url, country_id, uf, created_by)
VALUES (2, 'Rio jan','rio',1,'RJ',1);

INSERT INTO city(
        id, name, uf, pais, latitude, longitude, created_at,name_uri, state_id,country_id)
VALUES
(1, 'São Paulo'  ,'SP','br',-23.562880, -46.654659,'2012-09-28 03:55:36.899955','sao-paulo', 1,1),
(2, 'Outracidade','SP','br',-23.362880, -46.354659,'2012-09-28 03:55:36.899955','outra-cidade',1,1);







INSERT INTO institute(
            id, name, short_name, description, created_at, users_can_edit_value,
            users_can_edit_groups, can_use_custom_css, can_use_custom_pages)
VALUES
(
    1, 'Prefeituras', 'gov', 'administrado pelas prefeituras', now(), true, false, false, false
),
(
    2, 'Movimentos', 'org', 'administrado pelos movimentos', now(), true, true, true, true
);

insert into "network" (id, institute_id, domain_name, name, name_url, created_by)
values
(1, 1, 'prefeitura.gov', 'Prefeitura', 'pref', 1),
(2, 2, 'rnsp.org', 'RNSP', 'movim', 1),
(3, 2, 'latino.org', 'Rede latino americana', 'latino', 1);

INSERT INTO "user"(id, name, email, password, institute_id, city_id) VALUES
(2, 'adminpref','adminpref@email.com', '$2a$08$Hys9hzza605zZVKNJvdiBe9bHfdB4JKFnG8douGv53IW4e9M5cKrW',1, null),
(4, 'prefeitura','prefeitura@email.com', '$2a$08$Hys9hzza605zZVKNJvdiBe9bHfdB4JKFnG8douGv53IW4e9M5cKrW',1,1),

(3, 'adminmov','adminmov@email.com', '$2a$08$Hys9hzza605zZVKNJvdiBe9bHfdB4JKFnG8douGv53IW4e9M5cKrW',2, null),
(8, 'adminlat','adminlat@email.com', '$2a$08$Hys9hzza605zZVKNJvdiBe9bHfdB4JKFnG8douGv53IW4e9M5cKrW',2, null),
(5, 'movimento','movimento@email.com', '$2a$08$Hys9hzza605zZVKNJvdiBe9bHfdB4JKFnG8douGv53IW4e9M5cKrW',2,1),
(6, 'movimento2','movimento2@email.com', '$2a$08$Hys9hzza605zZVKNJvdiBe9bHfdB4JKFnG8douGv53IW4e9M5cKrW',2,2),
(7, 'latina','latina@email.com', '$2a$08$Hys9hzza605zZVKNJvdiBe9bHfdB4JKFnG8douGv53IW4e9M5cKrW',2,1);


INSERT INTO network_user ( network_id, user_id )
VALUES
(1,2),
(2,3),
(1,4),
(2,5),
(2,6),
(3,7),
(3,8);

-- role: superadmin                                     user:
INSERT INTO "user_role" ( user_id, role_id) VALUES (1, 0); -- superadmin

-- role: admins                                         user:
INSERT INTO "user_role" ( user_id, role_id) VALUES (2, 1); -- adminpref
INSERT INTO "user_role" ( user_id, role_id) VALUES (3, 1); -- adminmov
INSERT INTO "user_role" ( user_id, role_id) VALUES (8, 1); -- adminlat

-- role: user                                           user:
INSERT INTO "user_role" ( user_id, role_id) VALUES (4, 2); -- prefeitura
INSERT INTO "user_role" ( user_id, role_id) VALUES (5, 2); -- movimento
INSERT INTO "user_role" ( user_id, role_id) VALUES (6, 2); -- movimento2
INSERT INTO "user_role" ( user_id, role_id) VALUES (7, 2); -- latina





INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (19, 'População total', 'População total', 'pop_total', 1, '2012-10-01 16:50:42.857155', 'num', 'yearly', NULL, true);
INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (20, 'População rural e urbana', 'População rural e urbana', 'pop_rural_urbana', 1, '2012-10-01 16:51:55.453327', 'num', 'yearly', NULL, true);
INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (22, 'Divisão da população total por faixa etária', 'Divisão da população total por faixa etária', 'pop_faixa', 1, '2012-10-01 16:52:20.626508', 'num', 'yearly', NULL, true);
INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (23, 'Divisão da população total por gênero', 'Divisão da população total por gênero', 'pop_genero', 1, '2012-10-01 16:52:42.933181', 'num', 'yearly', NULL, true);
INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (24, 'Divisão da população total por raça/etnia', 'Divisão da população total por raça/etnia', 'pop_raca', 1, '2012-10-01 16:53:05.478149', 'num', 'yearly', NULL, true);
INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (26, 'Densidade demográfica - O número de pessoas por quilômetro quadrado', 'Densidade demográfica - O número de pessoas por quilômetro quadrado', 'densidade_demo', 1, '2012-10-01 16:57:19.059432', 'num', 'yearly', NULL, true);
INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (27, 'Área do Município', 'Área do Município', 'area_municipio', 1, '2012-10-01 16:58:44.813519', 'num', 'yearly', NULL, true);
INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (28, 'Expectativa de Vida: Esperança de vida ao nascer', 'Expectativa de Vida: Esperança de vida ao nascer', 'expect_vida', 1, '2012-10-01 16:58:54.33095', 'num', 'yearly', NULL, true);
INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (30, 'IDH Municipal', 'IDH Municipal', 'idh_municipal', 1, '2012-10-01 16:59:08.447301', 'num', 'yearly', NULL, true);
INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (31, 'Gini', 'Gini', 'gini', 1, '2012-10-01 17:00:11.909949', 'num', 'yearly', NULL, true);
INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (35, 'Produto Interno Bruto per capita', 'Produto Interno Bruto per capita', 'pib', 1, '2012-10-01 17:00:35.676173', 'num', 'yearly', NULL, true);
INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (36, 'Renda per capita', 'Renda per capita', 'renda_capita', 1, '2012-10-01 17:00:49.800921', 'num', 'yearly', NULL, true);
INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (38, 'Participação do eleitorado nas últimas eleições', 'Participação do eleitorado nas últimas eleições', 'part_eleitorado', 1, '2012-10-01 17:01:02.250016', 'num', 'yearly', NULL, true);
INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (39, 'Total de funcionários empregados no município', 'Total de funcionários empregados no município', 'total_func', 1, '2012-10-01 17:01:12.462152', 'num', 'yearly', NULL, true);
INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (40, 'Orçamento liquidado', 'Orçamento liquidado', 'orcamento_liq', 1, '2012-10-01 17:01:22.614466', 'num', 'yearly', NULL, true);

insert into axis (id, name) values (1, 'Governança');
insert into axis (id, name) values (2, 'Bens Naturais Comuns');
insert into axis (id, name) values (3, 'Equidade, Justiça Social e Cultura de Paz');
insert into axis (id, name) values (4, 'Gestão Local para a Sustentabilidade');
insert into axis (id, name) values (5, 'Planejamento e Desenho Urbano');
insert into axis (id, name) values (6, 'Cultura para a sustentabilidade');
insert into axis (id, name) values (7, 'Educação para a Sustentabilidade e Qualidade de Vida');
insert into axis (id, name) values (8, 'Economia Local, Dinâmica, Criativa e Sustentável');
insert into axis (id, name) values (9, 'Consumo Responsável e Opções de Estilo de Vida');
insert into axis (id, name) values (10, 'Melhor Mobilidade, Menos Tráfego');
insert into axis (id, name) values (11, 'Ação Local para a Saúde');
insert into axis (id, name) values (12, 'Do Local para o Global');
insert into axis (id, name) values (13, 'Planejando Cidades do Futuro');



insert into measurement_unit (name, short_name, user_id) values
('Quilometro', 'km', 1),
('Habitantes', 'habitantes', 1),
('Metro quadrado', 'm²', 1),
('Habitantes por quilometro quadrado', 'hab/km²', 1);

drop table if exists city_current_user;
create view city_current_user as

select c.id as city_id, u.id as user_id
from city c
join "user" u on u.city_id = c.id;

drop table if exists download_data;
drop table if exists download_variable;


CREATE OR REPLACE VIEW download_data AS
SELECT m.city_id,
       c.name AS city_name,
       e.name AS axis_name,
       m.indicator_id,
       i.name AS indicator_name,
       i.formula_human,
       i.formula,
       i.goal,
       i.goal_explanation,
       i.goal_source,
       i.goal_operator,
       i.explanation,
       i.tags,
       i.observations,
       i.period,
       m.variation_name,
       iv.order as variation_order,
       m.valid_from,
       m.value,
       a.goal AS user_goal,
       a.justification_of_missing_field,
       t.technical_information,
       m.institute_id,
       m.user_id,
       m.region_id,
       m.sources,
       r.name AS region_name,
       m.updated_at
FROM indicator_value m
JOIN city AS c ON m.city_id = c.id
JOIN indicator AS i ON i.id = m.indicator_id
LEFT JOIN axis AS e ON e.id = i.axis_id
LEFT JOIN indicator_variations iv on (case when m.variation_name = '' THEN FALSE ELSE (iv.name = m.variation_name AND iv.indicator_id = m.indicator_id AND iv.user_id IN (m.user_id, i.user_id)) END)
LEFT JOIN user_indicator a ON a.user_id = m.user_id AND a.valid_from = m.valid_from AND a.indicator_id = m.indicator_id
LEFT JOIN user_indicator_config t ON t.user_id = m.user_id AND t.indicator_id = i.id
LEFT JOIN region r ON r.id = m.region_id
WHERE active_value = TRUE;



CREATE  or replace VIEW download_variable AS
SELECT

    c.id as city_id,
    c.name as city_name,
    v.id as variable_id,
    v.type,
    v.cognomen,
    v.period::varchar,
    v.source as exp_source,
    v.is_basic,
    m.name as measurement_unit_name,
    v.name,
    vv.valid_from,
    vv.value,
    vv.observations,
    vv.source,
    vv.user_id,
    i.id as institute_id,
vv.created_at as updated_at

from variable_value vv
join variable v on v.id = vv.variable_id
left join measurement_unit m on m.id = v.measurement_unit_id
join "user" u on u.id = vv.user_id
join network_user nu on nu.user_id = u.id
join network n on n.id = nu.network_id
join institute i on i.id = n.institute_id
join city c on c.id = u.city_id
--where value is not null and value != ''
union all
SELECT

    c.id as city_id,
    c.name as city_name,
    -vvv.id as variable_id,
    v.type,
    v.name as cognomen,
    ix.period::varchar as period,
    null as exp_source,
    null as is_basic,
    null as measurement_unit_name,
    vvv.name || ': ' || v.name as name,
    vv.valid_from,
    vv.value,
    null as observations,
    null as source,
    vv.user_id,
    i.id as institute_id,
    vv.created_at as updated_at

from indicator_variables_variations_value vv
join indicator_variations vvv on vvv.id = indicator_variation_id
join indicator_variables_variations v on v.id = vv.indicator_variables_variation_id
join indicator ix on ix.id = vvv.indicator_id
join "user" u on u.id = vv.user_id
join network_user nu on nu.user_id = u.id
join network n on n.id = nu.network_id
join institute i on i.id = n.institute_id
join city c on c.id = u.city_id
where --value is not null and value != ''
active_value = TRUE
;



CREATE OR REPLACE FUNCTION compute_upper_regions(_ids integer[])
  RETURNS integer[] AS
$BODY$DECLARE
v_ret int[];
BEGIN
    create temp table _x as
    select
     r.upper_region,
     iv.valid_from,
     iv.user_id,
     iv.variable_id,

     sum(iv.value::numeric) as total,
     ARRAY(SELECT DISTINCT UNNEST( array_agg(iv.source) ) ORDER BY 1)  as sources

    from region r
    join region_variable_value iv on iv.region_id = r.id
    join variable v on iv.variable_id = v.id

    where r.upper_region in (
        select upper_region from region x where x.id in (SELECT unnest($1)) and x.depth_level= 3
    )
    and active_value = true
    and r.depth_level = 3

    and v.type in ('int', 'num')
    group by 1,2,3,4;

    delete from region_variable_value where (region_id, user_id, valid_from, variable_id) IN (
        SELECT upper_region, user_id, valid_from, variable_id from _x
    ) AND generated_by_compute = TRUE;

    insert into region_variable_value (
        region_id,
        variable_id,
        valid_from,
        user_id,
        value_of_date,
        value,
        source,
        generated_by_compute
    )
    select
        x.upper_region,
        x.variable_id,
        x.valid_from,
        x.user_id,
        x.valid_from,

        x.total::varchar,
        x.sources[1],
        true
    from _x x;

    select ARRAY(select upper_region from _x group by 1) into v_ret;
    drop table _x;

    create temp table _x as
    select
     r.upper_region,
     iv.valid_from,
     iv.user_id,
     iv.indicator_variation_id,
     iv.indicator_variables_variation_id,

     sum(iv.value::numeric) as total

    from region r
    join indicator_variables_variations_value iv on iv.region_id = r.id
    join indicator_variables_variations v on iv.indicator_variables_variation_id = v.id

    where r.upper_region in (
    select upper_region from region x where x.id in (SELECT unnest($1)) and x.depth_level= 3
    )
    and active_value = true
    and r.depth_level= 3

    and v.type in ('int', 'num')
    group by 1,2,3,4,5;

    delete from indicator_variables_variations_value where (region_id, user_id, valid_from, indicator_variation_id, indicator_variables_variation_id) IN (
        SELECT upper_region, user_id, valid_from, indicator_variation_id, indicator_variables_variation_id from _x
    ) AND generated_by_compute = TRUE;

    insert into indicator_variables_variations_value (
        region_id,
        indicator_variation_id,
        indicator_variables_variation_id,
        valid_from,
        user_id,
        value_of_date,
        value,
        generated_by_compute
    )
    select
        x.upper_region,
        x.indicator_variation_id,
        x.indicator_variables_variation_id,
        x.valid_from,
        x.user_id,
        x.valid_from,

        x.total::varchar,
        true
    from _x x;


    drop table _x;
    return v_ret;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION compute_upper_regions(integer[])
  OWNER TO postgres;



CREATE OR REPLACE FUNCTION clone_values(new_id integer, from_id integer, var_id integer, periods timestamp without time zone[])
  RETURNS int AS
$BODY$DECLARE integer_var int;
BEGIN

delete from variable_value
where variable_id = var_id
and   user_id = new_id
and valid_from in (select x from unnest(periods::date[]) as x);

insert into variable_value(
"value", variable_id, user_id, created_at, value_of_date, valid_from,
       valid_until, observations, source, file_id, cloned_from_user
)
SELECT

"value", variable_id, new_id, now(), value_of_date, valid_from,
       valid_until, observations, source, file_id, from_id

From variable_value
where variable_id = var_id
and   user_id = from_id
and valid_from in (select x from unnest(periods::date[]) as x);

GET DIAGNOSTICS integer_var = ROW_COUNT;


return integer_var;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (41, 'es', '*', 'Todas', 'Todas', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (40, 'es', '*', 'Dados abertos de indicadores', 'Indicadores de datos abiertas', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (42, 'es', '*', 'Indicador', 'Indicador', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (43, 'es', '*', 'Todos', 'Todos', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (44, 'es', '*', 'Formato', 'Formato', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (1, 'pt-br', '*', 'Cidades', 'Cidades', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (132, 'pt-br', '*', 'vezes', 'vezes', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (133, 'pt-br', '*', 'Descontados distritos cujo valor é zero', 'Descontados distritos cujo valor é zero', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (134, 'pt-br', '*', 'das subprefeituras', 'das subprefeituras', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (45, 'es', '*', 'CSV', 'CSV', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (27, 'es', '*', 'Cidades', 'Ciudades', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (28, 'es', '*', 'Indicadores', 'Indicadores', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (29, 'es', '*', 'Links', 'Links', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (30, 'es', '*', 'Contato', 'Contacto', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (31, 'es', '*', 'Brasil', 'Brasil', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (32, 'es', '*', 'Subprefeituras', 'Burgos', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (33, 'es', '*', 'Indicadores separados por eixos', 'Indicadores separados ejes', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (46, 'es', '*', 'XLS', 'XLS', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (34, 'es', '*', 'Carregando...', 'Cargando...', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (35, 'es', '*', 'Mapa do Site', 'Mapa del sitio', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (36, 'es', '*', 'comparar com outras cidades', 'comparar con otras ciudades', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (38, 'es', '*', 'Por Indicador', 'Por Indicator', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (39, 'es', '*', 'Selecione um estado acima e clique sobre os pontos do mapa para visualizar os indicadores', 'Seleccione un estado anterior y haga clic en el mapa para ver los marcadores señala', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (47, 'es', '*', 'XML', 'XML', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (48, 'es', '*', 'JSON', 'JSON', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (49, 'es', '*', 'Arquivo de indicadores', 'Indicadores Archivo', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (50, 'es', '*', 'Efetuar download dos indicadores', 'Asegúrese de descargar indicadores', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (51, 'es', '*', 'Nome da cidade', 'Nombre de la ciudad', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (52, 'es', '*', 'Nome do indicador', 'Nombre del indicador', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (53, 'es', '*', 'Data', 'Fecha', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (54, 'es', '*', 'Valor', 'Valor', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (55, 'es', '*', 'ID da cidade', 'City ID', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (56, 'es', '*', 'Eixo', 'Eje', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (57, 'es', '*', 'ID Indicador', 'Indicador ID', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (58, 'es', '*', 'Formula do indicador', 'Indicador Fórmula', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (59, 'es', '*', 'Meta do indicador', 'Indicador Objetivo', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (60, 'es', '*', 'Fonte da meta do indicador', 'Fuente del indicador de objetivos', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (61, 'es', '*', 'Tags do indicador', 'Indicador Etiquetas', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (62, 'es', '*', 'Faixa', 'Grupo', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (63, 'es', '*', 'Meta do valor', 'Valor objetivo', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (64, 'es', '*', 'Fontes', 'Fuentes', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (65, 'es', '*', 'Nome', 'Nombre', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (66, 'es', '*', 'ID', 'ID', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (67, 'es', '*', 'Tipo', 'Tipo', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (68, 'es', '*', 'Apelido', 'Nombre', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (69, 'es', '*', 'Fonte', 'Fuente', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (70, 'es', '*', 'Unidade de medida', 'Unidad de medida', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (71, 'es', '*', 'Fonte do valor', 'Fuente de valor', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (72, 'es', '*', 'Observações', 'Comentarios', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (73, 'es', '*', 'O arquivo de indicador contém as seguintes informações', 'El indicador de archivo contiene la siguiente información', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (74, 'es', '*', 'Descrição da meta do indicador', 'Descripción del indicador de destino', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (75, 'es', '*', 'Operação da meta do indicador', 'El funcionamiento del indicador de objetivos', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (76, 'es', '*', 'Descrição do indicador', 'Descripción del indicador', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (77, 'es', '*', 'Observações do indicador', 'Observaciones del indicador', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (78, 'es', '*', 'Período do indicador', 'Indicador Período', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (79, 'es', '*', 'Justificativa do valor não preenchido', 'Valor Justificación vacantes', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (80, 'es', '*', 'Região', 'Región', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (81, 'es', '*', 'se existir', 'si hay', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (82, 'es', '*', 'Período de atualização', 'Período de actualización', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (83, 'es', '*', 'É Básica?', 'Es básico?', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (84, 'es', '*', 'Arquivo de variáveis', 'Variables de archivo', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (85, 'es', '*', 'Efetuar download das variáveis', 'Asegúrese de descarga de las variables', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (86, 'es', '*', 'O arquivo de variável contém as seguintes informações', 'El archivo de variable contiene la siguiente información', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (100, 'es', '*', 'Cidade', 'Ciudad', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (88, 'es', '*', 'Média', 'Promedio', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (89, 'es', '*', 'Classificação', 'Clasificación', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (90, 'es', '*', 'Distritos', 'Distritos', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (91, 'es', '*', 'Alta / Melhor', 'Alto / Mejor', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (92, 'es', '*', 'Acima da média', 'Por encima del promedio', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (93, 'es', '*', 'Abaixo da média', 'Por debajo del promedio', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (94, 'es', '*', 'Baixa / Pior', 'Bajo ', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (95, 'es', '*', 'Média com base na soma dos números', 'Promedio sobre la base de la suma de los números', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (96, 'es', '*', 'dos distritos', 'del distritos', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (98, 'es', '*', 'mapa', 'mapa', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (87, 'es', '*', 'Subprefeitura', 'Burgo', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (97, 'es', '*', 'tabela', 'tabla', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (99, 'es', '*', 'gráficos', 'gráficos', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (101, 'es', '*', 'Desenvolvido por', 'Desarrollado por', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (103, 'es', '*', 'Download', 'Descargar', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (104, 'es', '*', 'Parceiros', 'Partners', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (37, 'es', '*', 'Dados abertos', 'Datos abiertos', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (135, 'pt-br', '*', 'gráficos', 'gráficos', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (2, 'pt-br', '*', 'Indicadores', 'Indicadores', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (3, 'pt-br', '*', 'Links', 'Links', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (5, 'pt-br', '*', 'Brasil', 'Brasil', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (6, 'pt-br', '*', 'tabela', 'tabela', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (7, 'pt-br', '*', 'mapa', 'mapa', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (8, 'pt-br', '*', 'Cidade', 'Cidade', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (9, 'pt-br', '*', 'Todas', 'Todas', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (10, 'pt-br', '*', 'Indicador', 'Indicador', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (11, 'pt-br', '*', 'Todos', 'Todos', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (12, 'pt-br', '*', 'Formato', 'Formato', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (13, 'pt-br', '*', 'CSV', 'CSV', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (14, 'pt-br', '*', 'XLS', 'XLS', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (15, 'pt-br', '*', 'XML', 'XML', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (16, 'pt-br', '*', 'JSON', 'JSON', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (17, 'pt-br', '*', 'Data', 'Data', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (18, 'pt-br', '*', 'Valor', 'Valor', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (19, 'pt-br', '*', 'Eixo', 'Eixo', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (20, 'pt-br', '*', 'Faixa', 'Faixa', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (21, 'pt-br', '*', 'Fontes', 'Fontes', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (22, 'pt-br', '*', 'Nome', 'Nome', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (23, 'pt-br', '*', 'ID', 'ID', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (24, 'pt-br', '*', 'Tipo', 'Tipo', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (25, 'pt-br', '*', 'Apelido', 'Apelido', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (26, 'pt-br', '*', 'Fonte', 'Fonte', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (4, 'pt-br', '*', 'Contato', 'Contato', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (105, 'pt-br', '*', 'Por Indicador', 'Por Indicador', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (106, 'pt-br', '*', 'Carregando...', 'Carregando...', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (107, 'pt-br', '*', 'Dados abertos', 'Dados abertos', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (108, 'pt-br', '*', 'Selecione um estado acima e clique sobre os pontos do mapa para visualizar os indicadores', 'Selecione um estado acima e clique sobre os pontos do mapa para visualizar os indicadores', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (109, 'pt-br', '*', 'Mapa do Site', 'Mapa do Site', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (110, 'pt-br', '*', 'Desenvolvido por', 'Desenvolvido por', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (111, 'pt-br', '*', 'Download', 'Download', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (112, 'pt-br', '*', 'Parceiros', 'Parceiros', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (113, 'pt-br', '*', 'Indicadores separados por eixos', 'Indicadores separados por eixos', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (114, 'pt-br', '*', 'Subprefeituras', 'Subprefeituras', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (115, 'pt-br', '*', 'comparar com outras cidades', 'comparar com outras cidades', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (116, 'pt-br', '*', 'Subprefeitura', 'Subprefeitura', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (117, 'pt-br', '*', 'Alta / Melhor', 'Alta / Melhor', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (118, 'pt-br', '*', 'Acima da média', 'Acima da média', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (119, 'pt-br', '*', 'Média', 'Média', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (120, 'pt-br', '*', 'Abaixo da média', 'Abaixo da média', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (121, 'pt-br', '*', 'Baixa / Pior', 'Baixa / Pior', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (122, 'pt-br', '*', 'Média com base na soma dos números', 'Média com base na soma dos números', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (123, 'pt-br', '*', 'dos distritos', 'dos distritos', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (124, 'pt-br', '*', 'Classificação', 'Classificação', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (125, 'pt-br', '*', 'Distrito', 'Distrito', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (126, 'pt-br', '*', 'Distritos', 'Distritos', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (127, 'pt-br', '*', 'Fator de desigualdade', 'Fator de desigualdade', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (128, 'pt-br', '*', 'Período', 'Período', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (129, 'pt-br', '*', 'Máximo', 'Máximo', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (130, 'pt-br', '*', 'Mínimo', 'Mínimo', NULL);
INSERT INTO lexicon (id, lang, lex, lex_key, lex_value, notes) VALUES (131, 'pt-br', '*', 'Desigualdade', 'Desigualdade', NULL);



SELECT pg_catalog.setval('lexicon_id_seq', 135, true);

-- Function: f_extract_period_edge(period_enum, timestamp without time zone)


CREATE OR REPLACE FUNCTION f_extract_period_edge(p_period period_enum, p_date timestamp without time zone)
  RETURNS tp_period_edges AS
$BODY$DECLARE
    v_edges tp_period_edges;
BEGIN
    v_edges.period_name := p_period;
    -- atencao, os retornos sao para ser comparados com < e nao <= !!
    -- veja bem o primeiro exemplo eh mantido em todos!

    CASE p_period
    WHEN 'daily' THEN

        v_edges.period_begin := p_date::date;
        v_edges.period_end   := p_date::date + '1 day'::interval;
    WHEN 'weekly' THEN

        v_edges.period_begin := date_trunc('week', p_date + '1 day'::interval ) - '1 day'::interval; -- vem segunda feira, volta pra domingo

        v_edges.period_end   := v_edges.period_begin + '7 days'::interval;
    WHEN 'monthly' THEN

        v_edges.period_begin := date_trunc('month', p_date);

        v_edges.period_end   := v_edges.period_begin + '1 month'::interval;
    WHEN 'bimonthly' THEN
        -- aqui segue a mesma logica, meses bimestrais são: [01 02], [03 04], [05 06], ...
        v_edges.period_begin := (extract('year' FROM p_date)::text || '-' ||
                (CASE WHEN extract('month' FROM p_date)::int % 2 = 0 THEN
                    (extract('month' FROM p_date) - 1)::text
                ELSE
                    extract('month' FROM p_date)::text
                END)
            ||'-01' )::date;

        v_edges.period_end   := v_edges.period_begin + '2 month'::interval;
    WHEN 'quarterly' THEN
        -- meses trimestrais são: [01 02 03] [04 05 06] [07 08 09] [10 11 12]
        v_edges.period_begin := date_trunc('quarter', p_date);

        v_edges.period_end   := v_edges.period_begin + '3 month'::interval;

    WHEN 'semi-annual' THEN

        v_edges.period_begin := (extract('year' FROM p_date)::text || '-' ||
                CASE WHEN extract('month' FROM p_date)::int <= 6 THEN '1' ELSE '7' END
            ||'-01' )::date;
        v_edges.period_end   := v_edges.period_begin + '6 month'::interval;

    WHEN 'yearly' THEN
        v_edges.period_begin := date_trunc('year', p_date);
        v_edges.period_end   := v_edges.period_begin + '1 year'::interval;

    WHEN 'decade' THEN
        v_edges.period_begin := date_trunc('decade', p_date);

        v_edges.period_end   := v_edges.period_begin + '10 years'::interval;
    ELSE
        RAISE EXCEPTION 'not supported period [%s]', p_period;
    END CASE;


    RETURN v_edges;
END;$BODY$
  LANGUAGE plpgsql STABLE
  COST 100;



CREATE OR REPLACE FUNCTION voltar_periodo(p_date timestamp without time zone, p_period period_enum, p_num int)
  RETURNS date AS
$BODY$DECLARE

BEGIN
    p_date := coalesce(
        p_date,
        ( select max(valid_from) from variable_value
          where variable_id in (select id from variable where period = p_period)
        ),
        current_date
    );

    IF (p_period IN ('weekly', 'monthly', 'yearly', 'decade') ) THEN
            RETURN ( p_date - ( p_num::text|| ' ' || replace(p_period::text, 'ly','') )::interval  )::date;
    ELSEIF (p_period = 'daily') THEN
        RETURN ( p_date - '1 day'::interval  )::date;
    ELSEIF (p_period = 'bimonthly') THEN
        RETURN ( p_date - ( (p_num*2)::text|| ' month' )::interval  )::date;
    ELSEIF (p_period = 'quarterly') THEN
        RETURN ( p_date - ( (p_num*3)::text|| ' month' )::interval  )::date;
    ELSEIF (p_period = 'semi-annual') THEN
        RETURN ( p_date - ( (p_num*6)::text|| ' month' )::interval  )::date;
    END IF;

    RETURN NULL;
END;$BODY$
  LANGUAGE plpgsql STABLE
  COST 100;

-- Function: ultimo_periodo(period_enum)

-- DROP FUNCTION ultimo_periodo(period_enum);

CREATE OR REPLACE FUNCTION ultimo_periodo(p_period period_enum)
  RETURNS date AS
$BODY$DECLARE
v_ret date;
BEGIN
    IF (p_period IN ('weekly', 'monthly', 'yearly', 'decade') ) THEN
            SELECT x.period_begin into v_ret
        FROM f_extract_period_edge(p_period, current_date - ( '1 ' ||replace(p_period::text, 'ly','') )::interval)x;
    ELSEIF (p_period = 'daily') THEN
            SELECT x.period_begin into v_ret
        FROM f_extract_period_edge(p_period, current_date -  '1 day'::interval) x;
    ELSEIF (p_period = 'bimonthly') THEN
        SELECT
        (extract('year' FROM current_date)::text || '-' ||
        (CASE WHEN extract('month' FROM current_date)::int % 2 = 0 THEN
                (extract('month' FROM current_date) - 1)::text
            ELSE
                extract('month' FROM current_date)::text
            END)
    ||'-01' )::date into v_ret;
    ELSEIF (p_period = 'quarterly') THEN
        SELECT x.period_begin into v_ret
        FROM f_extract_period_edge(p_period, current_date -  '3 months'::interval) x;
    ELSEIF (p_period = 'semi-annual') THEN
        SELECT x.period_begin into v_ret
        FROM f_extract_period_edge(p_period, current_date -  '6 months'::interval) x;
    END IF;

    RETURN v_ret;
END;$BODY$
  LANGUAGE plpgsql STABLE
  COST 100;
ALTER FUNCTION ultimo_periodo(period_enum)
  OWNER TO postgres;


COMMIT;
