package Iota::Model::KML::LineString;
use strict;
use utf8;
use Moose;

sub parse {
    my ( $self, $kml ) = @_;

    return undef
      unless ref $kml eq 'HASH'
      && exists $kml->{Document}
      && ref $kml->{Document} eq 'ARRAY'
      && exists $kml->{Document}[0]{Placemark}
      && ref $kml->{Document}[0]{Placemark} eq 'ARRAY';

    foreach my $place ( @{ $kml->{Document}[0]{Placemark} } ) {
        return undef
          unless ref $place eq 'HASH'
          && exists $place->{LineString}
          && ref $place->{LineString} eq 'ARRAY';

        foreach my $line ( @{ $place->{LineString} } ) {

            return undef
              unless exists $line->{coordinates}
              && ref $line->{coordinates} eq 'ARRAY';
            my $str = $line->{coordinates}[0] . ' ';
            my $ok = $str =~ /^(-?\d+\.\d+\,\s?-?\d+\.\d+\s)+$/o;
            return undef unless $ok;
        }
    }

    # valido!

    my @vecs;
    foreach my $place ( @{ $kml->{Document}[0]{Placemark} } ) {

        foreach my $line ( @{ $place->{LineString} } ) {

            my @latlng = split / /o, $line->{coordinates}[0];

            my @pos;
            foreach my $lnt (@latlng) {
                $lnt =~ /(.+)\,(.+)/o;
                push @pos, [ $1, $2 ];
            }
            push @vecs,
              {
                name   => undef,
                latlng => \@pos
              };
        }
    }

    return { vec => \@vecs };
}

1;
