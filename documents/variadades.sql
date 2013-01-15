/* Indicador
Distribuição de renda


variety_name="Faixas de salario minimo"

indicator_variations

name=faixas
Até 1/2 salário mínimo
Até 1/2 salário mínimo
Mais de 1 a 2 salários
Mais de 2 a 5 salários mínimos
Mais de 5 a 10 salários mínimos
Mais de 10 a 20 salários mínimos
Mais de 20 salários mínimos
Sem rendimento



indicator_variables_variations

name="Pessoas"
type="int"/"num"


indicator_variables_variations_value

*/


ALTER TABLE indicator
  ADD COLUMN variety_name character varying;
ALTER TABLE indicator
  ADD COLUMN indicator_type character varying not null default 'normal';


ALTER TABLE indicator
  ADD COLUMN all_variations_variables_are_required boolean not null default true;

ALTER TABLE indicator
  ADD COLUMN summarization_method varchar not null default 'sum';



ALTER TABLE variable
  DROP CONSTRAINT variable_fk_user_id;
ALTER TABLE variable
  ADD FOREIGN KEY (user_id) REFERENCES "user" (id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE variable_value
  DROP CONSTRAINT variable_value_fk_user_id;
ALTER TABLE variable_value
  DROP CONSTRAINT variable_value_fk_variable_id;
ALTER TABLE variable_value
  ADD FOREIGN KEY (user_id) REFERENCES "user" (id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE variable_value
  ADD FOREIGN KEY (variable_id) REFERENCES variable (id) ON UPDATE RESTRICT ON DELETE RESTRICT;


CREATE TABLE indicator_variations
(
  id serial NOT NULL,
  indicator_id integer NOT NULL,
  name character varying NOT NULL,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT indicator_variations_pkey PRIMARY KEY (id),
  CONSTRAINT indicator_variations_indicator_id_fkey FOREIGN KEY (indicator_id)
      REFERENCES indicator (id) MATCH SIMPLE
      ON UPDATE RESTRICT ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);


CREATE TABLE indicator_variables_variations
(
  id serial NOT NULL,
  indicator_variations integer NOT NULL,
  name character varying NOT NULL,
  type variable_type_enum NOT NULL DEFAULT 'int'::variable_type_enum,
  explanation character varying,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT indicator_variables_variations_pkey PRIMARY KEY (id),
  CONSTRAINT indicator_variables_variations_indicator_variations_fkey FOREIGN KEY (indicator_variations)
      REFERENCES indicator_variations (id) MATCH SIMPLE
      ON UPDATE RESTRICT ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);


CREATE TABLE indicator_variables_variations_value
(
  id bigserial NOT NULL,
  indicator_variation_id integer NOT NULL,
  value text,
  value_of_date timestamp without time zone,
  valid_from date,
  valid_until date,
  user_id integer NOT NULL,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT indicator_variables_variations_value_pkey PRIMARY KEY (id),
  CONSTRAINT indicator_variables_variations_valu_indicator_variation_id_fkey FOREIGN KEY (indicator_variation_id)
      REFERENCES indicator_variables_variations (id) MATCH SIMPLE
      ON UPDATE RESTRICT ON DELETE NO ACTION,
  CONSTRAINT indicator_variables_variation_indicator_variation_id_valid__key UNIQUE (indicator_variation_id, valid_from, user_id)
)
WITH (
  OIDS=FALSE
);

