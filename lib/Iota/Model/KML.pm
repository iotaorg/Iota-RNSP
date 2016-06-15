package Iota::Model::KML;
use Moose;
use utf8;
use JSON qw/encode_json decode_json/;

sub process {
    my ( $self, %param ) = @_;

    my $upload = $param{upload};

    my $file = $upload->tempname;

    my $out = `docker run --rm -v $file:/tmp/arq.kml:ro iota/togeojson togeojson /tmp/arq.kml`;
    if ( $? == -1 ) {
        die("Unssuported KML $!\n");
    }
    elsif ( $? & 127 ) {
        die( sprintf "child died with signal %d, %s coredump\n", ( $? & 127 ), ( $? & 128 ) ? 'with' : 'without' );
    }

    my $struct = eval { decode_json $out};
    die "Unssuported KML JSON $@\n" if $@;

    die "Unssuported KML: Missing FeatureCollection\n" unless $struct->{type} eq 'FeatureCollection';

    my @out;
    foreach my $feature ( @{ $struct->{features} } ) {
        next unless $feature->{type} eq 'Feature';
        next if $feature->{geometry}{type} eq 'Point';

        if ( exists $feature->{geometry}{geometries} ) {

            foreach my $subfeature ( @{ $feature->{geometry}{geometries} } ) {

                my @vec;
                foreach my $geom ( @{ $subfeature->{coordinates} } ) {

                    # multy polygon?
                    if ( ref $geom->[0] eq 'ARRAY' ) {

                        foreach my $geom2 ( @{$geom} ) {
                            my $num = scalar @$geom2;
                            die "Unssuported KML\n" if $num == 1;
                            push @vec, [ $geom2->[0], $geom2->[1] ];
                        }

                    }
                    else {
                        my $num = scalar @$geom;
                        die "Unssuported KML\n" if $num == 1;
                        push @vec, [ $geom->[0], $geom->[1] ];
                    }

                }

                push @out, { name => $feature->{properties}{name}, latlng => \@vec } if @vec;
            }

        }
        else {
            next unless ref $feature->{geometry}{coordinates} eq 'ARRAY';

            my @vec;
            foreach my $geom ( @{ $feature->{geometry}{coordinates} } ) {

                # multy polygon?
                if ( ref $geom->[0] eq 'ARRAY' ) {

                    foreach my $geom2 ( @{$geom} ) {
                        my $num = scalar @$geom2;
                        die "Unssuported KML\n" if $num == 1;
                        push @vec, [ $geom2->[0], $geom2->[1] ];
                    }

                }
                else {
                    my $num = scalar @$geom;
                    die "Unssuported KML\n" if $num == 1;
                    push @vec, [ $geom->[0], $geom->[1] ];
                }

            }

            push @out, { name => $feature->{properties}{name}, latlng => \@vec } if @vec;
        }

    }

    die "Unssuported KML\n" if scalar @out == 0;

    return { vec => \@out };

}

1;
