-- Table: lexicon

-- DROP TABLE lexicon;

CREATE TABLE lexicon
(
  id serial NOT NULL,
  lang character varying(15) DEFAULT NULL::character varying,
  lex character varying(255) DEFAULT NULL::character varying,
  lex_key text,
  lex_value text,
  notes text,
  CONSTRAINT lexicon_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);

