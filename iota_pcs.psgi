use strict;
use warnings;

use IOTA::PCS;

my $app = IOTA::PCS->apply_default_middlewares(IOTA::PCS->psgi_app);
$app;

