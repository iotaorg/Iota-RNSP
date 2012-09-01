
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
    $dbh->do("CREATE TYPE city_status_enum AS ENUM ('prefeitura', 'movimento');
        CREATE TYPE variable_type_enum AS ENUM ('str', 'int', 'num');
    ");
});
$schema->deploy;
$schema->storage->dbh_do(sub {
    my ($storage, $dbh) = @_;
    $dbh->do(q{INSERT INTO "role"(name) VALUES ('admin'), ('user'), ('app');
        INSERT INTO "user"(name, email, password) VALUES ('admin','admin_test@aware.com', '$2a$08$Hys9hzza605zZVKNJvdiBe9bHfdB4JKFnG8douGv53IW4e9M5cKrW');
        insert into "user_role" values (1, 1, 1);
    });
});




