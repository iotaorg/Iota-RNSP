use strict;
use warnings;

use Iota::PCS;

my $app = Iota::PCS->apply_default_middlewares(Iota::PCS->psgi_app);
$app;

