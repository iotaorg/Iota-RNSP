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

my $min = shift;
my $to  = shift;
$data->upsert(
    regions_id => [ $min .. $to ],
    user_id    => 11,
);
