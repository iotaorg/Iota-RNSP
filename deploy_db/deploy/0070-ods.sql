-- Deploy iota:0070-ods to pg
-- requires: 0069-usermetadata

BEGIN;

create table axis_attr  (
    id serial not null primary key,
    code varchar not null,
    props varchar not null
);

alter table axis add column attrs int[];


/*

insert into axis_attr (code, props) values
('1', '{"color":"#e5233b","img":1,"name":" erradicação da pobreza"}'),
('2', '{"name":" fome zero e agricultura sustentável","img":2,"color":"#dca63a"}'),
('3', '{"img":3,"name":" saúde e bem-estar","color":"#4c9e38"}'),
('4', '{"color":"#c51a2d","img":4,"name":" educação de qualidade"}'),
('5', '{"name":" igualdade de gênero","img":5,"color":"#ff3a20"}'),
('6', '{"img":6,"name":" água potável e saneamento","color":"#25bde2"}'),
('7', '{"color":"#fbc30a","img":7,"name":" energia limpa e acessível"}'),
('8', '{"img":8,"name":" trabalho decente e crescimento econômico","color":"#a21a42"}'),
('9', '{"img":9,"name":" indústria, inovação e infraestrutura","color":"#fe6925"}'),
('10', '{"img":10,"name":"redução das desigualdade","color":"#dd1367"}'),
('11', '{"name":"cidades e comunidades sustentáveis","img":11,"color":"#fd9d24"}'),
('12', '{"name":"consumo e produção responsáveis","img":12,"color":"#c08b2f"}'),
('13', '{"color":"#3f7e45","name":"ação contra a mudança global do clima","img":13}'),
('14', '{"color":"#0997d9","img":14,"name":"vida na água"}'),
('15', '{"color":"#56c02a","img":15,"name":"vida terrestre"}'),
('16', '{"img":16,"name":"paz, justiça e instituições eficazes","color":"#00689d"}'),
('17', '{"img":17,"name":"parcerias e meios de implementação","color":"#1a486a"}');


update axis set attrs = array[  ( select id from axis_attr where code = '5' ), ( select id from axis_attr where code = '10' ), ( select id from axis_attr where code = '16' ) ] where id = 1;
update axis set attrs = array[  ( select id from axis_attr where code = '2' ), ( select id from axis_attr where code = '6' ), ( select id from axis_attr where code = '11' ), ( select id from axis_attr where code = '12' ), ( select id from axis_attr where code = '14' ), ( select id from axis_attr where code = '15' ) ] where id = 2;
update axis set attrs = array[  ( select id from axis_attr where code = '1' ), ( select id from axis_attr where code = '3' ), ( select id from axis_attr where code = '5' ), ( select id from axis_attr where code = '9' ), ( select id from axis_attr where code = '10' ), ( select id from axis_attr where code = '11' ), ( select id from axis_attr where code = '16' ) ] where id = 3;
update axis set attrs = array[  ( select id from axis_attr where code = '11' ), ( select id from axis_attr where code = '12' ), ( select id from axis_attr where code = '16' ), ( select id from axis_attr where code = '17' ) ] where id = 4;
update axis set attrs = array[  ( select id from axis_attr where code = '11' ) ] where id = 5;
update axis set attrs = array[  ( select id from axis_attr where code = '4' ), ( select id from axis_attr where code = '11' ) ] where id = 6;
update axis set attrs = array[  ( select id from axis_attr where code = '4' ) ] where id = 7;
update axis set attrs = array[  ( select id from axis_attr where code = '2' ), ( select id from axis_attr where code = '7' ), ( select id from axis_attr where code = '8' ), ( select id from axis_attr where code = '9' ), ( select id from axis_attr where code = '12' ) ] where id = 8;
update axis set attrs = array[  ( select id from axis_attr where code = '6' ), ( select id from axis_attr where code = '7' ), ( select id from axis_attr where code = '11' ), ( select id from axis_attr where code = '12' ) ] where id = 9;
update axis set attrs = array[  ( select id from axis_attr where code = '3' ), ( select id from axis_attr where code = '11' ) ] where id = 10;
update axis set attrs = array[  ( select id from axis_attr where code = '2' ), ( select id from axis_attr where code = '3' ), ( select id from axis_attr where code = '5' ) ] where id = 11;
update axis set attrs = array[  ( select id from axis_attr where code = '7' ), ( select id from axis_attr where code = '11' ), ( select id from axis_attr where code = '13' ) ] where id = 12;


*/

COMMIT;
