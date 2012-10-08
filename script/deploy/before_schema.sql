CREATE TYPE variable_type_enum AS ENUM ('str', 'int', 'num');

CREATE TYPE sort_direction_enum AS ENUM ('greater value','greater rating','lowest value','lowest rating');

CREATE TYPE period_enum AS ENUM ('daily', 'weekly', 'monthly', 'bimonthly', 'quarterly', 'semi-annual', 'yearly', 'decade');

CREATE TYPE tp_period_edges AS
(period_name character varying,
period_begin  date,
period_end date);