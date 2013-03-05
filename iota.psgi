use strict;
use warnings;

use Iota;

my $app = Iota->apply_default_middlewares(Iota->psgi_app);
$app;

