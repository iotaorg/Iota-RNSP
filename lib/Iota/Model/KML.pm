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

    my $file = $upload->tempname;

    my $str_or_file = $self->remove_xsi($file);

    my $kml = XMLin(
        $str_or_file,
        ForceArray => 1,
        KeyAttr    => {},
    );

    my $parsed;

    # keep that in order!
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

sub remove_xsi {
    my ($self, $file) = @_;

    # trata o erro Undeclared prefix: xsi
    my $str = q{xsi:schemaLocation="http://www.opengis.net/kml/2.2 http://schemas.opengis.net/kml/2.2.0/ogckml22.xsd http://www.google.com/kml/ext/2.2 http://code.google.com/apis/kml/schema/kml22gx.xsd"};
    $str = quotemeta($str);

    open(my $fh, '<:utf8', $file) or die $!;

    my $start_xml = '';
    $start_xml .= <$fh> for (1..4);


    if ($start_xml =~ /$str/){
        # ok, read all and return the content

        $start_xml =~ s/\s+$str//g;

        while (my $l = <$fh>){
            $start_xml .= $l;
        }

        close $fh;
        return $start_xml;
    }

    close $fh;
    return $file; # return the filename
}

1;
