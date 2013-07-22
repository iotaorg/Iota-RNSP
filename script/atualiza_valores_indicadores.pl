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

    #indicators => [
    #    $data->indicators_from_variation_variables(
    #        variables => [ 6,7 ]
    #    )
    #],
    #dates   => [ '2012-01-01' ],
    #user_id => 152,

);
