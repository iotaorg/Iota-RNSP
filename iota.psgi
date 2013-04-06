use strict;
use warnings;
use lib 'lib';
use Iota;

my $app = Iota->apply_default_middlewares(Iota->psgi_app);
$app;

