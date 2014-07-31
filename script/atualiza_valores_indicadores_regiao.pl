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
my $schema = Iota->model('DB')->schema;

use Iota::IndicatorData;

my $data = Iota::IndicatorData->new( schema => $schema );

my $min = shift;
my $to  = shift;

$data->upsert( regions_id => [ map { $_->id } $schema->resultset('Region')->search( { depth_level => $_ } )->all ], )
  for ( 3, 2 );
