
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
                    INSERT INTO "user"(id, name, email, password) VALUES (1, 'admin','admin_test@aware.com', '$2a$08$Hys9hzza605zZVKNJvdiBe9bHfdB4JKFnG8douGv53IW4e9M5cKrW');
                    SELECT setval('user_id_seq', 2);
                    SELECT setval('role_id_seq', 10);
                    INSERT INTO "user_role" ( user_id, role_id) VALUES (1, 1); -- admin user /admin role
                    drop table IF EXISTS prefeitos;
                    drop table IF EXISTS movimentos;

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




