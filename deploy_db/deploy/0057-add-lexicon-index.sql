-- Deploy 0057-add-lexicon-index
-- requires: 0056-download-data-with-values

BEGIN;

delete from lexicon where id not in (select min(id ) from lexicon group by lang, lex_key);

drop index if exists ix_lexicon_words;
CREATE unique index ix_lexicon_words on lexicon(lang, md5(lex_key));

COMMIT;
