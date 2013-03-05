package Iota::PCS::Model::File::XLS;
use strict;
use Moose;
use utf8;
use DateTime;
use DateTime::Format::Pg;

use Spreadsheet::ParseExcel::Stream;
use DateTime::Format::Excel;

use Text::Iconv;


sub parse {
    my ($self, $file) = @_;

    my $xls = Spreadsheet::ParseExcel::Stream->new($file);

    my %expected_header = (
        id    => qr /\b(id da v.riavel|v.riavel id)\b/io,
        date  => qr /\bdata\b/io,
        value => qr /\bvalor\b/io
    );

    my @rows;
    my $ok      = 0;
    my $ignored = 0;
    my $header_found;
    while ( my $sheet = $xls->sheet() ) {

        my $header_map = {};
        $header_found  = 0;

        while ( my $row = $sheet->row ) {

            my @data = @$row;

            if (!$header_found){

                for my $col ( 0 .. (scalar @data - 1) ) {
                    my $cell = $data[$col];
                    next unless $cell;

                    foreach my $header_name (keys %expected_header){

                        if ($cell =~ $expected_header{$header_name}){
                            $header_found++;
                            $header_map->{$header_name} = $col;
                        }
                    }
                }
            }else{

                # aqui você pode verificar se foram encontrados todos os campos que você precisa
                # neste caso, achar apenas 1 cabeçalho já é o suficiente

                my $registro = {};

                foreach my $header_name (keys %$header_map){
                    my $col = $header_map->{$header_name};

                    my $value = $data[$col];

                    # aqui é uma regra que você escolhe, pois as vezes o valor da célula pode ser nulo
                    next if !defined $value || $value =~ /^\s*$/;
                    $value =~ s/^\s+//;
                    $value =~ s/\s+$//;
                    $registro->{$header_name} = $value;
                }

                if (keys %$registro == 3 ){

                    $registro->{date} = $registro->{date} =~ /^20[123][0-9]$/
                        ? $registro->{date} . '-01-01'
                        :
                            $registro->{date} =~ /^\d{4}\-\d{2}\-\d{2}$/
                            ? $registro->{date}
                            : DateTime::Format::Excel->parse_datetime( $registro->{date} )->ymd;
                    $ok++;
                    push @rows, $registro;

                }else{
                    $ignored++;
                }

            }
        }
    }

    return {
        rows    => \@rows,
        ignored => $ignored,
        ok      => $ok,
        header_found => !!$header_found
    };
}

1;
