INSERT INTO city(
        id, name, uf, pais, latitude, longitude, created_at,name_uri)
VALUES (1, 'São Paulo','SP','br',-23.562880, -46.654659,'2012-09-28 03:55:36.899955','sao-paulo');
SELECT setval('public.city_id_seq', 30, true);

INSERT INTO "role"(id,name) VALUES (1,'admin'),(2,'user'), (3,'app'), (4,'_prefeitura'), (5,'_movimento');
INSERT INTO "user"(id, name, email, password) VALUES (1, 'admin','admin@cidadessustentaveis.org.br', '$2a$08$Hys9hzza605zZVKNJvdiBe9bHfdB4JKFnG8douGv53IW4e9M5cKrW');

INSERT INTO "user"(id, name, email, password) VALUES (2, 'prefeitura','prefeitura@cidadessustentaveis.org.br', '$2a$08$Hys9hzza605zZVKNJvdiBe9bHfdB4JKFnG8douGv53IW4e9M5cKrW');

SELECT setval('user_id_seq', 10);
SELECT setval('role_id_seq', 10);

INSERT INTO "user_role" ( user_id, role_id) VALUES (1, 1); -- admin user /admin role_id

INSERT INTO "user_role" ( user_id, role_id) VALUES (2, 2); -- prefeitura user / user role
INSERT INTO "user_role" ( user_id, role_id) VALUES (2, 4); -- prefeitura user / prefeitura role

drop table IF EXISTS prefeitos;
drop table IF EXISTS movimentos;

SELECT pg_catalog.setval('variable_id_seq', 40, true);

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
SELECT setval('public.axis_id_seq', 100, true);


insert into measurement_unit (name, short_name, user_id) values
('Quilometro', 'km', 1),
('Habitantes', 'habitantes', 1),
('Metro quadrado', 'm²', 1),
('Habitantes por quilometro quadrado', 'hab/km²', 1);


create view movimentos as
select
    b.id as city_id,
    a.id as user_id
from "user" a
inner join city b on a.city_id = b.id
inner join user_role ur on ur.user_id = a.id
where ur.role_id = (select id from role where name ='_movimento');

create view prefeitos as
select
    b.id as city_id,
    a.id as user_id
from "user" a
inner join city b on a.city_id = b.id
inner join user_role ur on ur.user_id = a.id
where ur.role_id = (select id from role where name ='_prefeitura');