package Iota::Model::KML::Polygon;
use strict;
use utf8;
use Moose;

sub parse {
    my ( $self, $kml ) = @_;

    return undef
      unless ref $kml eq 'HASH'
      && exists $kml->{Document}
      && ref $kml->{Document} eq 'ARRAY'
      &&

      exists $kml->{Document}[0]{Folder}
      && ref $kml->{Document}[0]{Folder} eq 'ARRAY'
      && @{ $kml->{Document}[0]{Folder} } == 1
      && exists $kml->{Document}[0]{Folder}[0]{Placemark}
      && ref $kml->{Document}[0]{Folder}[0]{Placemark} eq 'ARRAY';

    foreach my $place ( @{ $kml->{Document}[0]{Folder}[0]{Placemark} } ) {

        return undef
          unless ref $place eq 'HASH'
          && exists $place->{Polygon}
          && ref $place->{Polygon} eq 'ARRAY'
          && exists $place->{Polygon}[0]{outerBoundaryIs}
          && ref $place->{Polygon}[0]{outerBoundaryIs} eq 'ARRAY'
          && exists $place->{Polygon}[0]{outerBoundaryIs}[0]{LinearRing}
          && ref $place->{Polygon}[0]{outerBoundaryIs}[0]{LinearRing} eq 'ARRAY'
          && exists $place->{Polygon}[0]{outerBoundaryIs}[0]{LinearRing}[0]{coordinates}
          && ref $place->{Polygon}[0]{outerBoundaryIs}[0]{LinearRing}[0]{coordinates} eq 'ARRAY';

        my $str = $place->{Polygon}[0]{outerBoundaryIs}[0]{LinearRing}[0]{coordinates}[0] . ' ';
        my $xok = $str =~ /^(-?\d+\.\d+\,\s?-?\d+\.\d+,\d+\.\d+\s+)+$/o;
        return undef unless $xok;
    }

    # valido!

    my @vecs;
    foreach my $place ( @{ $kml->{Document}[0]{Folder}[0]{Placemark} } ) {

        my @latlng = split / /o, $place->{Polygon}[0]{outerBoundaryIs}[0]{LinearRing}[0]{coordinates}[0];

        my @pos;
        foreach my $lnt (@latlng) {
            $lnt =~ /(.+)\,(.+)\,\d+\.\d+/o;
            push @pos, [ $1, $2 ];
        }

        push @vecs,
          {
            name => exists $place->{name} && ref $place->{name} eq 'ARRAY' ? $place->{name}[0] : undef,
            latlng => \@pos
          };

    }

    return { vec => \@vecs };
}

1;
