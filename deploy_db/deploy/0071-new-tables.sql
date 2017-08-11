-- Deploy iota:0071-new-tables to pg
-- requires: 0070-ods

BEGIN;

/* melhor criar outra coisa chamda 'eixo' que faz a mesma coisa do que criar uma tabela chamada 'dimension' e outra 'category' */
CREATE TABLE public.axis_dim1
(
  id serial NOT NULL PRIMARY KEY,
  name text NOT NULL,
  description text NOT NULL,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  created_by int not null
);

CREATE TABLE public.axis_dim2
(
  id serial NOT NULL PRIMARY KEY,
  name text NOT NULL,
  description text NOT NULL,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  created_by int not null
);

alter table indicator add column axis_dim1_id int references axis_dim1(id);
alter table indicator add column axis_dim2_id int references axis_dim2(id);


COMMIT;
