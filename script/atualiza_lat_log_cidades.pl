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

use Geo::Coder::Google;

my $geo_google = Geo::Coder::Google->new( apiver => 3 );

my @not_sent = $schema->resultset('City')->search( { latitude => undef } )->all;

foreach my $mail (@not_sent) {

    my $location = $geo_google->geocode( location => $mail->name . ' ' . $mail->uf . ' Brasil' );

    my %values;
    $values{latitude} = $location->{geometry}{location}{lat}
      unless defined $values{latitude};
    $values{longitude} = $location->{geometry}{location}{lng}
      unless defined $values{longitude};

    $mail->update( \%values );
    sleep 1;

}
