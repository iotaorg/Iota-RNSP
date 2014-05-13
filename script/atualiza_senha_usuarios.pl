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

my @not_sent = ();

open( my $f, '<:utf8', $ARGV[0] ) or die 'cant find <' . $ARGV[0] . $!;

while ( my $l = <$f> ) {
    $l =~ /^\s*([^;]+);([^\s]+)\s*$/;
    push @not_sent, { email => $1, password => $2 };
}

use DDP;
my $x = \@not_sent;
p $x;
print "Confirm? say yes! \n";
$x = <STDIN>;
die('not accepted') unless $x =~ /yes/;

foreach my $mail (@not_sent) {

    my $who = $schema->resultset('User')->search(
        {
            email => $mail->{email}
        }
    )->next;

    if ($who) {
        $who->update( { password => $mail->{password} } );
        print "$mail->{email} ok\n";
    }
    else {
        print "$mail->{email} nao encontrado\n";
    }

}
