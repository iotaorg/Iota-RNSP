use strict;
use utf8;
use DateTime;
use DateTime::Format::Pg;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use JSON::XS;
use Text::CSV_XS;

my $file = $ARGV[0];

my $csv = Text::CSV_XS->new( { binary => 1 } )
  or die "Cannot use CSV: " . Text::CSV_XS->error_diag();
open my $fh, "<:encoding(utf8)", $file or die "$file: $!";

my %expected_header = (
    nome_cidade                                => qr/nome_cidade$/,
    nome_uf                                    => qr/nome_uf$/,
    nome_usuario                               => qr/nome_usuario$/,
    nome_eixo                                  => qr/nome_eixo$/,
    programa_de_metas                          => qr/^programa_de_metas$/,
    qtde_indicadores_preenchido                => qr/^qtde_indicadores_preenchido$/,
    qtde_indicadores_preenchido_ou_justificado => qr/qtde_indicadores_preenchido_ou_justificado$/,
    total_indicadores_eixo                     => qr/total_indicadores_eixo$/,
    city_id                                    => qr/city_id$/,
    axis_id                                    => qr/axis_id$/,
    user_id                                    => qr/user_id$/,
);

my @rows;
my $ok      = 0;
my $ignored = 0;

my $header_map   = {};
my $header_found = 0;

my $ig = {};

my $eixos = {};
my $rot   = {};

while ( my $row = $csv->getline($fh) ) {

    my @data = @$row;

    if ( !$header_found ) {

        for my $col ( 0 .. ( scalar @data - 1 ) ) {
            my $cell = $data[$col];
            next unless $cell;

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

            my $value = $data[$col];

            # aqui é uma regra que você escolhe, pois as vezes o valor da célula pode ser nulo
            next if !defined $value || $value =~ /^\s*$/;
            $value =~ s/^\s+//;
            $value =~ s/\s+$//;
            $registro->{$header_name} = $value;
        }

        if ( exists $registro->{qtde_indicadores_preenchido_ou_justificado} ) {

            $registro->{qtde_indicadores_justificado} =
              $registro->{qtde_indicadores_preenchido_ou_justificado} - $registro->{qtde_indicadores_preenchido};

            $registro->{nome_eixo} = $registro->{nome_eixo} . ' (' . $registro->{axis_id} . ')';

            $eixos->{ $registro->{nome_eixo} } = 1;

            my $key = join '|', $registro->{nome_uf}, $registro->{nome_cidade}, $registro->{user_id},
              $registro->{programa_de_metas};

            $rot->{$_}{$key}{ $registro->{nome_eixo} } = $registro->{$_}
              for
              qw/qtde_indicadores_justificado qtde_indicadores_preenchido_ou_justificado qtde_indicadores_preenchido/;

        }
        else {
            use DDP;
            p @data;
            $ignored++;
        }

    }
}

$csv->eof or $csv->error_diag();
close $fh;

my @axiseq = sort keys %$eixos;
use DDP;
p \@axiseq;

while ( my ( $filename, $whos ) = each %$rot ) {

    open $fh, ">:encoding(utf8)", "/tmp/new_$filename.csv" or die "/tmp/new_$filename.csv: $!";

    my $csv = Text::CSV_XS->new( { binary => 1, auto_diag => 1 } );
    $csv->eol("\r\n");

    $csv->print( $fh, [ 'nome_uf', 'nome_cidade', 'user_id', 'programa metas', 'total', @axiseq ] );

    while ( my ( $key, $quants ) = each %$whos ) {
        my $total = 0;

        $total += $quants->{$_} || 0 for @axiseq;

        my @first = split /\|/, $key;
        my @values = map { $quants->{$_} || 0 } @axiseq;

        my $arr = [ @first, $total, @values ];

        $csv->print( $fh, $arr );

    }
    close $fh or die "csv: $!";

}

#p $rot;
#

