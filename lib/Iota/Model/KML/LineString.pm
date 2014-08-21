package Iota::Model::KML::LineString;
use strict;
use utf8;
use Moose;

sub parse {
    my ( $self, $kml ) = @_;

    # nao remover, pois quebra o parser o polygon dependendo do caso
    $kml = { Document => [ $kml->{Document}[0]{Folder}[0] ] }
      if ref $kml eq 'HASH'
      && exists $kml->{Document}[0]{Folder}[0]
      && ref $kml->{Document}[0]{Folder} eq 'ARRAY';


    return undef
      unless ref $kml eq 'HASH'
      && exists $kml->{Document}
      && ref $kml->{Document} eq 'ARRAY'
      && exists $kml->{Document}[0]{Placemark}
      && ref $kml->{Document}[0]{Placemark} eq 'ARRAY';

    foreach my $place ( @{ $kml->{Document}[0]{Placemark} } ) {

        my $may_name = $place->{name} if exists $place->{name};

        $place = $place->{MultiGeometry}[0]
          if ref $place eq 'HASH'
          && exists $place->{MultiGeometry}
          && ref $place->{MultiGeometry} eq 'ARRAY';

        $place->{name} = $may_name if defined $may_name;

        next if ref $place eq 'HASH' && $place->{LookAt};

        return undef
          unless ref $place eq 'HASH'
          && exists $place->{LineString}
          && ref $place->{LineString} eq 'ARRAY';
        foreach my $line ( @{ $place->{LineString} } ) {

            return undef
              unless exists $line->{coordinates}
              && ref $line->{coordinates} eq 'ARRAY';
            my $str = $line->{coordinates}[0] . ' ';


            my $ok  = ($str =~ /^(-?\d+\.\d+\,\s?-?\d+\.\d+\s)+$/o) || ($str =~ /(?:-?\d+(?:\.\d+)?\,\s?-?\d+(?:\.\d+)?,\d+(?:\.\d+)?)/);

            return undef unless $ok;
        }
    }

    # valido!

    my @vecs;
    foreach my $place ( @{ $kml->{Document}[0]{Placemark} } ) {

        foreach my $line ( @{ $place->{LineString} } ) {

            my $str = $line->{coordinates}[0] . ' ';

            my $with_zero = $str =~ /(?:-?\d+(?:\.\d+)?\,\s?-?\d+(?:\.\d+)?,\d+(?:\.\d+)?)/;

            if ($with_zero){
                $str =~ s/^\s+//;
                $str =~ s/\s+$//;
            }

            my @latlng = split / /o, $str;

            my @pos;
            foreach my $lnt (@latlng) {
                if ($with_zero){
                    $lnt =~ /(.+)\,(.+)\,\d+(?:\.\d+)?/o;
                    push @pos, [ $1, $2 ];
                }else{
                    $lnt =~ /(.+)\,(.+)/o;
                    push @pos, [ $1, $2 ];
                }
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
