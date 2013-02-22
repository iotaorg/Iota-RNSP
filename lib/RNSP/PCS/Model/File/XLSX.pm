package RNSP::PCS::Model::File::XLSX;
use strict;
use Moose;
use utf8;
use DateTime;
use DateTime::Format::Pg;
use Spreadsheet::XLSX;

use Text::Iconv;

has _iconv => (
    is      => 'rw',
    isa     => 'Text::Iconv',
    lazy    => 1,
    default => sub { Text::Iconv->new("utf-8", "utf-8") }
);


sub parse {
    my ($self, $file) = @_;

    my $excel  = Spreadsheet::XLSX->new($file, $self->_iconv);

    my %expected_header = (
        id    => qr /\b(id da v.riavel|v.riavel id)\b/io,
        date  => qr /\bdata\b/io,
        value => qr /\bvalor\b/io
    );

    for my $worksheet ( @{$excel -> {Worksheet}} ) {

        my ( $row_min, $row_max ) = $worksheet->row_range();
        my ( $col_min, $col_max ) = $worksheet->col_range();

        my $header_map     = {};
        my $header_found   = 0;

        for my $row ( $row_min .. $row_max ) {

            if (!$header_found){
                for my $col ( $col_min .. $col_max ) {
                    my $cell = $worksheet->get_cell( $row, $col );
                    next unless $cell;

                    foreach my $header_name (keys %expected_header){

                        if ($cell->value() =~ $expected_header{$header_name}){
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

                    my $cell = $worksheet->get_cell( $row, $col );
                    next unless $cell;

                    my $value = $cell->value();

                    # aqui é uma regra que você escolhe, pois as vezes o valor da célula pode ser nulo
                    next unless $value;

                    $registro->{$header_name} = $value;
                }

                if (keys %$registro){
use DDP; p $registro;

                }
            }

        }
    }
}

1;
