package Iota::Model::File::XLS;
use strict;
use Moose;
use utf8;
use DateTime;
use DateTime::Format::Pg;

use DateTime::Format::Excel;

use Spreadsheet::ParseExcel;

use Encode;

sub parse {
    my ( $self, $file ) = @_;

    my $xls_tmp = Spreadsheet::ParseExcel->new();
    my $xls  = $xls_tmp->parse($file);

    if ( !defined $xls ) {
        die $xls_tmp->error(), ".\n";
    }

    my %expected_header = (
        id    => qr /\b(id da v.ri.vel|v.ri.vel id)\b/io,
        date  => qr /\bdata\b/io,
        value => qr /\bvalor\b/io,

        obs    => qr /\bobserva..o\b/io,
        source => qr /\bfonte\b/io,

        region_id => qr /\b(id da regi.o|regi.o id)\b/io,
    );

    my @rows;
    my $ok      = 0;
    my $ignored = 0;
    my $header_found;
    for my $worksheet (  $xls->worksheets() ) {

next unless $worksheet;

        my ( $row_min, $row_max ) = $worksheet->row_range();
        my ( $col_min, $col_max ) = $worksheet->col_range();

        my $header_map = {};
        $header_found = 0;

        for my $row ( $row_min .. $row_max ) {

            # my @data = @$row;

            if ( !$header_found ) {

                for my $col ( $col_min .. $col_max ) {
                    my $cell = $worksheet->get_cell( $row, $col );
                    next unless $cell;
                    $cell =  $cell->value();

                    foreach my $header_name ( keys %expected_header ) {

                        if ( $cell =~ $expected_header{$header_name} ) {
                            $header_found++;
                            $header_map->{$header_name} = $col;
                        }
                    }
                }
            }
            else {

                # aqui você pode verificar se foram encontrados todos os campos que você precisa
                # neste caso, achar apenas 1 cabeçalho já é o suficiente

                my $registro = {};

                foreach my $header_name ( keys %$header_map ) {
                    my $col = $header_map->{$header_name};

                    my $cell = $worksheet->get_cell( $row, $col );
                    next unless $cell;

                    my $value = $cell->value();

                    # aqui é uma regra que você escolhe, pois as vezes o valor da célula pode ser nulo
                    next if !defined $value || $value =~ /^\s*$/;
                    $value =~ s/^\s+//;
                    $value =~ s/\s+$//;

                    eval{$value = decode( 'iso-8859-15', $value )};
                    $registro->{$header_name} = $value;
                }

                if ( exists $registro->{id} && exists $registro->{date} && exists $registro->{value} ) {


                    $registro->{date} =
                        $registro->{date} =~ /^20[0123][0-9]$/       ? $registro->{date} . '-01-01'
                      : $registro->{date} =~ /^\d{4}\-\d{2}\-\d{2}$/ ? $registro->{date}
                      :   DateTime::Format::Excel->parse_datetime( $registro->{date} )->ymd;

                    $ok++;

                    die 'invalid variable id' unless $registro->{id} =~ /^\d+$/;
                    die 'invalid region id' if $registro->{region_id} && $registro->{region_id} !~ /^\d+$/;

                    push @rows, $registro;

                }
                else {
                    $ignored++;
                }

            }
        }
    }

    return {
        rows         => \@rows,
        ignored      => $ignored,
        ok           => $ok,
        header_found => !!$header_found
    };
}

1;
