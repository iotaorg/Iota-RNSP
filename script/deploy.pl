
use lib './lib';

use RNSP::PCS::Schema;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(RNSP::PCS);
my $config = RNSP::PCS->config;

my $schema = RNSP::PCS::Schema->connect(
    $config->{'Model::DB'}{connect_info}{dsn},
    $config->{'Model::DB'}{connect_info}{user},
    $config->{'Model::DB'}{connect_info}{password} );

$schema->storage->dbh_do(sub {
    my ($storage, $dbh) = @_;
    $dbh->do("CREATE TYPE variable_type_enum AS ENUM ('str', 'int', 'num');");
});

$schema->deploy;

$schema->storage->dbh_do(sub {
            my ($storage, $dbh) = @_;
                $dbh->do(q{
                    INSERT INTO "role"(id,name) VALUES (1,'admin'),(2,'user'), (3,'app'), (4,'_prefeitura'), (5,'_movimento');
                    INSERT INTO "user"(id, name, email, password) VALUES (1, 'admin','admin@cidadessustentaveis.org.br', '$2a$08$Hys9hzza605zZVKNJvdiBe9bHfdB4JKFnG8douGv53IW4e9M5cKrW');
                    SELECT setval('user_id_seq', 2);
                    SELECT setval('role_id_seq', 10);
                    INSERT INTO "user_role" ( user_id, role_id) VALUES (1, 1); -- admin user /admin role
                    drop table IF EXISTS prefeitos;
                    drop table IF EXISTS movimentos;

                    SELECT pg_catalog.setval('variable_id_seq', 40, true);

                    INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (19, 'populacao_total', 'População total', 'populacao_total', 1, '2012-10-01 16:50:42.857155', 'str', 'year', NULL, true);
                    INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (20, 'populacao_urbana', 'População rural e urbana', 'populacao_urbana', 1, '2012-10-01 16:51:55.453327', 'str', 'year', NULL, true);
                    INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (22, 'divisao_pop_total_faixa_etaria', 'Divisão da população total por faixa etária', 'divisao_pop_total_faixa_etaria', 1, '2012-10-01 16:52:20.626508', 'str', 'year', NULL, true);
                    INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (23, 'divisao_pop_total_por_genero', 'Divisão da população total por gênero', 'divisao_pop_total_por_genero', 1, '2012-10-01 16:52:42.933181', 'str', 'year', NULL, true);
                    INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (24, 'divisao_pop_total_total_raca', 'Divisão da população total por raça/etnia', 'divisao_pop_total_total_raca', 1, '2012-10-01 16:53:05.478149', 'str', 'year', NULL, true);
                    INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (26, 'densidade_demografica', 'Densidade demográfica - O número de pessoas por quilômetro quadrado', 'densidade_demografica', 1, '2012-10-01 16:57:19.059432', 'str', 'year', NULL, true);
                    INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (27, 'area_municipio', 'Área do Município', 'area_municipio', 1, '2012-10-01 16:58:44.813519', 'str', 'year', NULL, true);
                    INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (28, 'expectativa_vida', 'Expectativa de Vida: Esperança de vida ao nascer', 'expectativa_vida', 1, '2012-10-01 16:58:54.33095', 'str', 'year', NULL, true);
                    INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (30, 'idh_municipal', 'IDH Municipal', 'idh_municipal', 1, '2012-10-01 16:59:08.447301', 'str', 'year', NULL, true);
                    INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (31, 'gini', 'Gini', 'gini', 1, '2012-10-01 17:00:11.909949', 'str', 'year', NULL, true);
                    INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (35, 'pib_capita', 'Produto Interno Bruto per capita', 'pib_capita', 1, '2012-10-01 17:00:35.676173', 'str', 'year', NULL, true);
                    INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (36, 'renda_capita', 'Renda per capita', 'renda_capita', 1, '2012-10-01 17:00:49.800921', 'str', 'year', NULL, true);
                    INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (38, 'participacao_eleitorado', 'Participação do eleitorado nas últimas eleições', 'participacao_eleitorado', 1, '2012-10-01 17:01:02.250016', 'str', 'year', NULL, true);
                    INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (39, 'total_funcionario', 'Total de funcionários empregados no município', 'total_funcionario', 1, '2012-10-01 17:01:12.462152', 'str', 'year', NULL, true);
                    INSERT INTO variable (id, name, explanation, cognomen, user_id, created_at, type, period, source, is_basic) VALUES (40, 'orcamento_liquidado', 'Orçamento liquidado', 'orcamento_liquidado', 1, '2012-10-01 17:01:22.614466', 'str', 'year', NULL, true);


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

                    });
                });




