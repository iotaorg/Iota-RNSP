
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
    $dbh->do("CREATE TYPE city_status_enum AS ENUM ('prefeitura', 'movimento');");
});
$schema->deploy;

