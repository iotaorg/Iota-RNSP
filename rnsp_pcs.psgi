use strict;
use warnings;

use RNSP::PCS;

my $app = RNSP::PCS->apply_default_middlewares(RNSP::PCS->psgi_app);
$app;

