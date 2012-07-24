
use lib './lib';

use RNSP::PCS::Schema;

my $schema = RNSP::PCS::Schema->connect( 'dbi:Pg:dbname=rnsp_pcs', 'rnsp_pcs', 'rnsp_pcs' );
$schema->deploy;

