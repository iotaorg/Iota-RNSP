package Iota::Model::KML;
use Moose;
use utf8;
use JSON qw/encode_json/;
use XML::Simple qw(:strict);

use Iota::Model::KML::LineString;
use Iota::Model::KML::Polygon;
use Iota::Model::KML::LinearRing;

sub process {
    my ( $self, %param ) = @_;

    my $upload = $param{upload};
    my $schema = $param{schema};

    my $kml = XMLin(
        $upload->tempname,
        ForceArray => 1,
        KeyAttr    => {},
    );

    my $parsed;

    for my $mod (qw/LinearRing LineString Polygon/) {
        my $class = "Iota::Model::KML::$mod";
        my $test  = $class->new->parse($kml);
        next unless defined $test;

        $parsed = $test;
        last;
    }

    if ( defined $parsed ) {

        return $parsed;

    }
    else {

        die("Unssuported KML\n");
    }

}

1;
