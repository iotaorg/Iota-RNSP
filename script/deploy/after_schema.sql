SELECT setval('city_id_seq', 30, true);
SELECT setval('axis_id_seq', 100, true);
SELECT setval('institute_id_seq', 10, true);
SELECT setval('variable_id_seq', 40, true);
SELECT setval('network_id_seq', 10, true);
SELECT setval('user_id_seq', 10, true);
SELECT setval('role_id_seq', 10, true);
SELECT setval('country_id_seq', 10, true);
SELECT setval('state_id_seq', 10, true);


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
       i.goal,
       i.goal_explanation,
       i.goal_source,
       i.goal_operator,
       i.explanation,
       i.tags,
       i.observations,
       i.period,
       m.variation_name,
       m.valid_from,
       m.value,
       a.goal AS user_goal,
       a.justification_of_missing_field,
       t.technical_information,
       m.institute_id,
       m.user_id,
       m.region_id,
       m.sources,
       r.name AS region_name
FROM indicator_value m
JOIN city AS c ON m.city_id = c.id
JOIN indicator AS i ON i.id = m.indicator_id
LEFT JOIN axis AS e ON e.id = i.axis_id
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
    i.id as institute_id

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
    i.id as institute_id

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
            x.sources,
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