use strict;
use warnings;
use utf8;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Config::General;
use Template;

use Encode;
use JSON qw / decode_json /;

use Iota;
my $schema = Iota->model('DB');

use Iota::IndicatorData;

my $data = Iota::IndicatorData->new( schema => $schema );

$data->upsert(
    regions_id => [2],
    user_id => 11,
    indicators => [5]
);
