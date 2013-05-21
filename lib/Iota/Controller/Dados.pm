
=head1 Download de dados dos indicadores

=head2 Descrição

Os indicadores da Iota estao disponveis pelas seguintes URLs:

- todos indicadores da cidade
/$rede/br/$UF/$nome-cidade/indicadores.$tipo

- todos dados do indicador
/$rede/br/$UF/$nome-cidade/$nome-indicador/dados.$tipo

- todos os dados do indicador de todas as cidades
/$rede/$nome-indicador/dados.$tipo


rede = 'movimento' e 'network' são aceitos.
tipo = csv | json | xml

o Check SUM em md5 é disponivel na mesma URL, com o final '.checksum'



=cut

package Iota::Controller::Dados;
use Moose;
BEGIN { extends 'Catalyst::Controller' }
use utf8;
use File::Basename;
use JSON::XS;
use Iota::IndicatorFormula;
use Text::CSV_XS;
use Spreadsheet::WriteExcel;
use XML::Simple qw(:strict);
use Digest::MD5;

# download de todos os endpoints caem aqui
sub _download {
    my ( $self, $c ) = @_;

    my $data_rs = $c->model('DB::DownloadData')->search({
        institute_id => $c->stash->{institute}->id
    }, {
        result_class => 'DBIx::Class::ResultClass::HashRefInflator'
    });


    my $network = $c->stash->{network};

    my $file = $network->name_url;
    $file .= '_' . $c->stash->{pais} . '_' . $c->stash->{estado} . '_' . $c->stash->{cidade}
      if $c->stash->{cidade};
    $file .= '_' . $c->stash->{indicator}{name_url}
      if $c->stash->{indicator};
    $file .= '.' . $c->stash->{type};

    my $path = ( $c->config->{downloads}{tmp_dir} || '/tmp' ) . '/' . lc $file;

    if ( -e $path ) {
        # apaga o arquivo caso passe 12 horas
        my $epoch_timestamp = ( stat($path) )[9];
        unlink($path) if time() - $epoch_timestamp > 10;
    }
    $self->_download_and_detach( $c, $path ) if -e $path;

    if ($c->stash->{cidade}){
        # procula pela cidade, se existir.
        my $cities = $c->model('DB::City')->as_hashref->search(
            {
                pais     => lc $c->stash->{pais},
                uf       => uc $c->stash->{estado},
                name_uri => lc $c->stash->{cidade}
            }
        )->next;

        my $id = $cities ? $cities->{id} : -9012345; # download vazio
        $data_rs = $data_rs->search({ city_id => $id });
    }

    if (exists $c->stash->{indicator}){
        $data_rs = $data_rs->search({ indicator_id => $c->stash->{indicator}{id} });
    }

    if (exists $c->stash->{region}){
        $data_rs = $data_rs->search({ region_id => $c->stash->{region}{id} });
    }


    my @lines = (
        [
            'ID da cidade',
            'Nome da cidade ',
            'Eixo',
            'ID Indicador',
            'Nome do indicador',
            'Formula do indicador',
            'Meta do indicador',
            'Descrição da meta do indicador',
            'Fonte da meta do indicador',
            'Operação da meta do indicador',
            'Descrição do indicador',
            'Tags do indicador',
            'Observações do indicador',
            'Período do indicador',
            'Faixa',
            'Data',
            'Valor',
            'Meta do valor',
            'Justificativa do valor não preenchido',
            'Informações Tecnicas',
            'Nome da região',
            'Fontes'
        ]
    );

    while ( my $data = $data_rs->next ) {
        my @this_row = (
            $data->{city_id},
            $data->{city_name},
            $data->{axis_name},
            $data->{indicator_id},
            $data->{indicator_name},
            $data->{formula_human},
            $data->{goal},
            $data->{goal_explanation},
            $data->{goal_source},
            $data->{goal_operator},
            $data->{explanation},
            $data->{tags},
            $data->{observations},
            $self->_period_pt( $data->{period} ),
            $data->{variation_name},
            $self->ymd2dmy( $data->{valid_from}),
            $data->{value},
            $data->{user_goal},
            $data->{justification_of_missing_field},
            $data->{technical_information},
            $data->{region_name},
            ref $data->{sources} eq 'ARRAY' ? (join "\n", @{$data->{sources}}) : ''
        );
        push @lines, \@this_row;
    }

    eval { $self->lines2file( $c, $path, \@lines ) };
    if ($@) {
        $path =~ s/\.check//;
        unlink($path);
        $path .= '.check';
        unlink($path);
        die $@;
    }
    $self->_download_and_detach( $c, $path );
}

sub _period_pt {
    my ( $self, $period ) = @_;

    return 'semanal' if $period eq 'weekly';
    return 'mensal'  if $period eq 'monthly';
    return 'anual'   if $period eq 'yearly';
    return 'decada'  if $period eq 'decade';
    return 'diario'  if $period eq 'daily';

    return $period;    # outros nao usados
}

sub _add_variables {
    my ( $self, $c, $hash, $arr ) = @_;
    my @rows = $c->model('DB')->resultset('Variable')->as_hashref->search( undef, { order_by => 'name' } )->all;
    my $i = scalar @$arr;
    foreach my $var (@rows) {
        $hash->{ $var->{id} } = $i++;
        push @$arr, $var->{name};
    }
}

sub _concate_variables {
    my ( $self, $c, $header, $values, $row ) = @_;

    my %id_val = map { $_->{varid} => $_->{value} } @$values;

    foreach my $id ( sort { $header->{$a} <=> $header->{$b} } keys %$header ) {
        if ( exists $id_val{$id} ) {
            push @$row, $id_val{$id};
        }
        else {
            push @$row, '';
        }
    }

}

sub ymd2dmy {
    my ( $self, $str ) = @_;
    return "$3/$2/$1" if ( $str =~ /(\d{4})-(\d{2})-(\d{2})/ );
    return '';
}

sub lines2file {
    my ( $self, $c, $path, $lines ) = @_;

    $path =~ s/\.check//;

    open my $fh, ">:encoding(utf8)", $path or die "$path: $!";
    if ( $path =~ /csv$/ ) {
        my $csv = Text::CSV_XS->new( { binary => 1, eol => "\r\n" } )
          or die "Cannot use CSV: " . Text::CSV_XS->error_diag();

        $csv->print( $fh, $_ ) for @$lines;

    }
    elsif ( $path =~ /json$/ ) {

        print $fh encode_json($lines);

    }
    elsif ( $path =~ /xml$/ ) {
        print $fh XMLout( $lines, KeyAttr => { server => 'linhas' } );

    }
    elsif ( $path =~ /xls$/ ) {
        binmode($fh);
        my $workbook = Spreadsheet::WriteExcel->new($fh);

        # Add a worksheet
        my $worksheet = $workbook->add_worksheet();

        #  Add and define a format
        my $bold = $workbook->add_format(); # Add a format
        $bold->set_bold();

        # Write a formatted and unformatted string, row and column notation.
        my $total = @$lines;

        for (my $row = 0; $row < $total; $row++){

            if ($row==0){
                $worksheet->write($row, 0, $lines->[$row], $bold);
            }else{
                my $total_col = @{$lines->[$row]};
                for (my $col = 0; $col < $total_col; $col++){
                    my $val = $lines->[$row][$col];

                    if ($val && $val =~ /^\=/){
                        $worksheet->write_string($row, $col, $val);
                    }else{
                        $worksheet->write($row, $col, $val);
                    }
                }
            }
        }

    }
    else {
        die("not a valid format");
    }
    close $fh or die "$path: $!";

    open( $fh, $path ) or die "Can't open '$path': $!";
    binmode($fh);
    my $md5 = Digest::MD5->new;
    while (<$fh>) {
        $md5->add($_);
    }
    close($fh);

    open $fh, '>', "$path.check" or die "$path: $!";
    print $fh $md5->hexdigest;

}

sub _download_and_detach {
    my ( $self, $c, $path ) = @_;

    if ( $c->stash->{type} =~ /(json)/ ) {
        $c->response->content_type('application/json; charset=UTF-8');
    }
    elsif ( $c->stash->{type} =~ /(xml)/ ) {
        $c->response->content_type('text/xml');
    }
    elsif ( $c->stash->{type} =~ /(csv)/ ) {
        $c->response->content_type('text/csv');
    }
    elsif ( $c->stash->{type} =~ /(xls)/ ) {
        $c->response->content_type('application/vnd.ms-excel');
    }
    $c->response->headers->header( 'content-disposition' => "attachment;filename=" . basename($path) );

    open( my $fh, '<:raw', $path );
    $c->res->body($fh);

    $c->detach;
}

##################################################
### be happy to read bellow this line!

# network CSV
sub pref_dados_csv : Chained('/institute_load') : PathPart('indicadores.csv') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'csv';
}

sub pref_dados_csv_check : Chained('/institute_load') : PathPart('indicadores.csv.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'csv.check';
}

sub down_pref_dados_csv : Chained('pref_dados_csv') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_dados_csv_check : Chained('pref_dados_csv_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}


# network xLS
sub pref_dados_xls : Chained('/institute_load') : PathPart('indicadores.xls') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xls';
}

sub pref_dados_xls_check : Chained('/institute_load') : PathPart('indicadores.xls.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xls.check';
}

sub down_pref_dados_xls : Chained('pref_dados_xls') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_dados_xls_check : Chained('pref_dados_xls_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# network XML
sub pref_dados_xml : Chained('/institute_load') : PathPart('indicadores.xml') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml';
}

sub pref_dados_xml_check : Chained('/institute_load') : PathPart('indicadores.xml.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml.check';
}

sub down_pref_dados_xml : Chained('pref_dados_xml') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_dados_xml_check : Chained('pref_dados_xml_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# network JSON
sub pref_dados_json : Chained('/institute_load') : PathPart('indicadores.json') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'json';
}

sub pref_dados_json_check : Chained('/institute_load') : PathPart('indicadores.json.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'json.check';
}

sub down_pref_dados_json : Chained('pref_dados_json') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_dados_json_check : Chained('pref_dados_json_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

######## dados por cidades

# network CSV
sub pref_dados_cidade_csv : Chained('/network_cidade') : PathPart('indicadores.csv') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'csv';
}

sub pref_dados_cidade_csv_check : Chained('/network_cidade') : PathPart('indicadores.csv.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'csv.check';
}

sub down_pref_dados_cidade_csv : Chained('pref_dados_cidade_csv') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_dados_cidade_csv_check : Chained('pref_dados_cidade_csv_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# network CSV windows
sub xls_pref_dados_cidade_csv : Chained('/network_cidade') : PathPart('indicadores.xls') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xls';
}

sub xls_pref_dados_cidade_csv_check : Chained('/network_cidade') : PathPart('indicadores.xls.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xls.check';
}

sub xls_down_pref_dados_cidade_csv : Chained('xls_pref_dados_cidade_csv') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub xls_down_pref_dados_cidade_csv_check : Chained('xls_pref_dados_cidade_csv_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# network XML
sub pref_dados_cidade_xml : Chained('/network_cidade') : PathPart('indicadores.xml') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml';
}

sub pref_dados_cidade_xml_check : Chained('/network_cidade') : PathPart('indicadores.xml.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml.check';
}

sub down_pref_dados_cidade_xml : Chained('pref_dados_cidade_xml') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_dados_cidade_xml_check : Chained('pref_dados_cidade_xml_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# network JSON
sub pref_dados_cidade_json : Chained('/network_cidade') : PathPart('indicadores.json') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'json';
}

sub pref_dados_cidade_json_check : Chained('/network_cidade') : PathPart('indicadores.json.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'json.check';
}

sub down_pref_dados_cidade_json : Chained('pref_dados_cidade_json') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_dados_cidade_json_check : Chained('pref_dados_cidade_json_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# dados por indicador

#################

# network CSV
sub pref_dados_cidade_indicadorcsv : Chained('/network_indicator') : PathPart('dados.csv') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'csv';
}

sub pref_dados_cidade_indicadorcsv_check : Chained('/network_indicator') : PathPart('dados.csv.checksum') :
  CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'csv.check';
}

sub down_pref_dados_cidade_indicadorcsv : Chained('pref_dados_cidade_indicadorcsv') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_dados_cidade_indicadorcsv_check : Chained('pref_dados_cidade_indicadorcsv_check') : PathPart('') :
  Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# network CSV-windows
sub xls_pref_dados_cidade_indicadorcsv : Chained('/network_indicator') : PathPart('dados.xls') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xls';
}

sub xls_pref_dados_cidade_indicadorcsv_check : Chained('/network_indicator') : PathPart('dados.xls.checksum') :
  CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xls.check';
}

sub xls_down_pref_dados_cidade_indicadorcsv : Chained('xls_pref_dados_cidade_indicadorcsv') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub xls_down_pref_dados_cidade_indicadorcsv_check : Chained('xls_pref_dados_cidade_indicadorcsv_check') : PathPart('') :
  Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# network XML
sub pref_dados_cidade_indicadorxml : Chained('/network_indicator') : PathPart('dados.xml') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml';
}

sub pref_dados_cidade_indicadorxml_check : Chained('/network_indicator') : PathPart('dados.xml.checksum') :
  CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml.check';
}

sub down_pref_dados_cidade_indicadorxml : Chained('pref_dados_cidade_indicadorxml') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_dados_cidade_indicadorxml_check : Chained('pref_dados_cidade_indicadorxml_check') : PathPart('') :
  Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# network JSON
sub pref_dados_cidade_indicadorjson : Chained('/network_indicator') : PathPart('dados.json') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'json';
}

sub pref_dados_cidade_indicadorjson_check : Chained('/network_indicator') : PathPart('dados.json.checksum') :
  CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'json.check';
}

sub down_pref_dados_cidade_indicadorjson : Chained('pref_dados_cidade_indicadorjson') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_dados_cidade_indicadorjson_check : Chained('pref_dados_cidade_indicadorjson_check') : PathPart('') :
  Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

###################
# download do indicador direto (todas as cidades)

#################

# network CSV
sub pref_indicador_csv : Chained('/network_indicador') : PathPart('dados.csv') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'csv';
}

sub pref_indicador_csv_check : Chained('/network_indicador') : PathPart('dados.csv.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'csv.check';
}

sub down_pref_indicador_csv : Chained('pref_indicador_csv') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_indicador_csv_check : Chained('pref_indicador_csv_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# network CSV windows
sub xls_pref_indicador_csv : Chained('/network_indicador') : PathPart('dados.xls') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xls';
}

sub xls_pref_indicador_csv_check : Chained('/network_indicador') : PathPart('dados.xls.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xls.check';
}

sub xls_down_pref_indicador_csv : Chained('xls_pref_indicador_csv') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub xls_down_pref_indicador_csv_check : Chained('xls_pref_indicador_csv_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}



# network XML
sub pref_indicador_xml : Chained('/network_indicador') : PathPart('dados.xml') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml';
}

sub pref_indicador_xml_check : Chained('/network_indicador') : PathPart('dados.xml.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml.check';
}

sub down_pref_indicador_xml : Chained('pref_indicador_xml') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_indicador_xml_check : Chained('pref_indicador_xml_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# network JSON
sub pref_indicador_json : Chained('/network_indicador') : PathPart('dados.json') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'json';
}

sub pref_indicador_json_check : Chained('/network_indicador') : PathPart('dados.json.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'json.check';
}

sub down_pref_indicador_json : Chained('pref_indicador_json') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_indicador_json_check : Chained('pref_indicador_json_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

1;

