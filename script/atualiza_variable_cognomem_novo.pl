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

use Text2URI;
my $t = Text2URI->new();

my @not_sent = $schema->resultset('Variable')->all;

foreach my $mail (@not_sent) {

    $mail->update( { cognomen => $t->translate( $mail->name, '_' ) } );

}
