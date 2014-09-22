-- Deploy 0058-auto-add-lex
-- requires: 0057-add-lexicon-index

BEGIN;

alter table lexicon add column translated_from_lexicon boolean;

COMMIT;
