use strict;
use warnings;
use utf8;
use Parse::CSV;
use DDP;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Config::General;
use Template;

use Encode;
use JSON qw / decode_json /;

use Iota;
my $schema = Iota->model('DB');

open my $fh, '<', 'documents/variaveis-premio-crianca.csv' or die 'not open';

my $objects = Parse::CSV->new(
    handle   => $fh,
    sep_char => ';',
    names    => [
        qw/name explanation cognomen user_id type period source is_basic measurement_unit_id user_type summarization_method/
    ]
);
while ( my $object = $objects->fetch ) {
    $object->{measurement_unit_id} = undef;
    $object->{source}              = undef;

    my $variable = $schema->resultset('Variable')
      ->search( { cognomen => $object->{cognomen} } )->next;

    $schema->resultset('Variable')->create( { %{$object} } )
      unless $variable;
    print $variable->id . "\n";
}
