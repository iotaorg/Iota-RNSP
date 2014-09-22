create table _foo (id int, origin_lang varchar,lang varchar,lex_key varchar,lex_value varchar);
 copy _foo from '/tmp/foo.csv' CSV HEADER;

update lexicon a set lang=x.lang, origin_lang=x.origin_lang,lex_key=x.lex_key,lex_value=x.lex_value from _foo x where a.id=x.id;


create temp table _ind as
select x.id from indicator x join indicator_network_visibility a on a.indicator_id =x.id where visibility_level='network' and a.network_id=3;


create temp table _ind as
select x.id from indicator x where x.id in (516,
517,518,519,520,521,101,522,102,767,523,524,117,525,122,121,123,120,9,124,19,20,125,8,526,190,954,955,527,528,529,
185,530,531,532,533,534,535,536);

copy(select id, origin_lang, lang, lex_key, lex_value from lexicon where lex_key in (
	select name from indicator where id in (select id from _ind)
	union
	select explanation from indicator where id in (select id from _ind)
	union
	select source from indicator where id in (select id from _ind)
	union
	select goal_source from indicator where id in (select id from _ind)
	union
	select goal_operator from indicator where id in (select id from _ind)
	union
	select observations from indicator where id in (select id from _ind)
	union
	select variety_name from indicator where id in (select id from _ind)
	union
	select formula_human from indicator where id in (select id from _ind)
	union
	select name from variable where id in (select variable_id from indicator_variable where indicator_id in (select id from _ind))
	union
	select explanation from variable where id in (select variable_id from indicator_variable where indicator_id in (select id from _ind))
	union
	select cognomen from variable where id in (select variable_id from indicator_variable where indicator_id in (select id from _ind))
	union
	select source from variable where id in (select variable_id from indicator_variable where indicator_id in (select id from _ind))
)
order by lex_key, lex_value) to '/tmp/out.csv' CSV HEADER;
