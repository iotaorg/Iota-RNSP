
=head1 Download de arquivos de variveis

=head2 Descrição

Download das variaveis do sistema

- todas variaveis de uma cidade
/$rede/br/$UF/$nome-cidade/variaveis.$tipo

- todas variaveis utilizadas pela cidade + indicador
/$rede/br/$UF/$nome-cidade/$nome-indicador/variaveis.$tipo

- todas as variaveis de todas as cidades daquele indicador
/$rede/$nome-indicador/variaveis.$tipo


rede = 'movimento' e 'network' são aceitos.
tipo = csv | json | xml

o Check SUM em md5 é disponivel na mesma URL, com o final '.checksum'


=cut

package Iota::Controller::Variaveis;
use Moose;

BEGIN { extends 'Catalyst::Controller::REST' }
__PACKAGE__->config( default => 'application/json' );
use utf8;
use JSON::XS;
use Iota::IndicatorFormula;
use Text::CSV_XS;
use File::Basename;
use XML::Simple qw(:strict);
use Digest::MD5;

# download de todos os endpoints caem aqui
sub _download {
    my ( $self, $c ) = @_;

    my $network = $c->stash->{network};

    my $file = 'variaveis.' . $network->name_url;
    $file .= '_' . $c->stash->{pais} . '_' . $c->stash->{estado} . '_' . $c->stash->{cidade}
      if $c->stash->{cidade};
    $file .= '_' . $c->stash->{region}->name_url
      if exists $c->stash->{region} && $c->stash->{region};
    $file .= '_' . $c->stash->{indicator}{name_url}
      if $c->stash->{indicator};
    $file .= '.' . $c->stash->{type};

    my $path = ( $c->config->{downloads}{tmp_dir} || '/tmp' ) . '/' . lc $file;

    if ( -e $path ) {

        # apaga o arquivo caso passe 12 horas
        my $epoch_timestamp = ( stat($path) )[9];
        unlink($path) if time() - $epoch_timestamp > 60;
    }
    $self->_download_and_detach( $c, $path ) if -e $path;

    my @lines = (
        [
            'ID da cidade', 'Nome da cidade ',
            'ID', 'Tipo', 'Apelido', 'Período de atualização',
            'É Básica?', 'Unidade de medida',
            'Nome', 'Data', 'Valor', 'Observações', 'Fonte preenchida',
            'Nome Região'
        ]
    );

    my $data_rs =
      $c->model('DB')->resultset( exists $c->stash->{region} ? 'ViewDownloadVariablesRegion' : 'DownloadVariable' )
      ->search(
        { institute_id => $c->stash->{institute}->id },
        {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',

            ( bind => [ ( $c->stash->{region}->id ) x 2 ] ) x !!$c->stash->{region}
        }
      );

    if ( $c->stash->{cidade} ) {

        # procula pelas cidades para procurar os usuarios
        my $city = $c->model('DB::City')->as_hashref->search(
            {
                pais     => lc $c->stash->{pais},
                uf       => uc $c->stash->{estado},
                name_uri => lc $c->stash->{cidade}
            }
        )->next;

        my $id = $city ? $city->{id} : -9012345;    # download vazio

        my $user = $c->model('DB::User')->as_hashref->search(
            {
                city_id                    => $id,
                'network_users.network_id' => $network->id
            },
            { join => 'network_users' }
        )->next;

        $data_rs = $data_rs->search( { user_id => $user ? $user->{id} : -9012345 } );
    }

    if ( exists $c->stash->{indicator} ) {
        $data_rs = $data_rs->search(
            {
                variable_id => {
                    'in' => [
                        (
                            map { $_->variable_id }
                              $c->model('DB::IndicatorVariable')
                              ->search( { indicator_id => $c->stash->{indicator}{id} } )->all
                        ),

                        (
                            map { -( $_->id ) }
                              $c->model('DB::IndicatorVariation')
                              ->search( { indicator_id => $c->stash->{indicator}{id} } )->all
                        )
                    ]
                }
            }
        );
    }

    if ( exists $c->stash->{region} && $c->stash->{region} ) {
        $data_rs = $data_rs->search( { region_id => $c->stash->{region}->id } );
    }

    while ( my $data = $data_rs->next ) {
        my @this_row = (
            $data->{city_id},
            $data->{city_name},
            $data->{variable_id},
            $data->{type} eq 'int'   ? 'Inteiro'
            : $data->{type} eq 'str' ? 'Alfanumérico'
            : 'Valor',
            $data->{cognomen},
            $self->_period_pt( $data->{period} ),

            $data->{is_basic} ? 'sim' : 'não',
            $data->{measurement_unit_name},
            $data->{name},
            $self->ymd2dmy( $data->{valid_from} ),
            $data->{value},
            $data->{observations},
            $data->{source},
            $data->{region_name},
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
        my $bold = $workbook->add_format();    # Add a format
        $bold->set_bold();

        # Write a formatted and unformatted string, row and column notation.
        my $total = @$lines;

        for ( my $row = 0 ; $row < $total ; $row++ ) {

            if ( $row == 0 ) {
                $worksheet->write( $row, 0, $lines->[$row], $bold );
            }
            else {
                my $total_col = @{ $lines->[$row] };
                for ( my $col = 0 ; $col < $total_col ; $col++ ) {
                    my $val = $lines->[$row][$col];

                    if ( $val && $val =~ /^\=/ ) {
                        $worksheet->write_string( $row, $col, $val );
                    }
                    else {
                        $worksheet->write( $row, $col, $val );
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

sub download_variables : Chained('/institute_load') PathPart('download-variables') Args(0) ActionClass('REST') {

}

sub download_variables_GET {
    my ( $self, $c ) = @_;
    my $params = $c->req->params;
    my @objs;

    my $data_rs =
      $c->model( exists $params->{region_id} ? 'DB::ViewDownloadVariablesRegion' : 'DB::DownloadVariable' )
      ->search( { institute_id => $c->stash->{institute}->id },
        { result_class => 'DBIx::Class::ResultClass::HashRefInflator' } );

    if ( exists $params->{region_id} ) {
        my @ids = split /,/, $params->{region_id};

        $self->status_bad_request( $c, message => 'invalid region_id' ), $c->detach
          unless Iota::Controller::Dados::int_validation( $self, @ids );

        $data_rs = $data_rs->search(
            {
                region_id => { 'in' => \@ids }
            }
        );
    }

    if ( exists $params->{user_id} ) {
        my @ids = split /,/, $params->{user_id};

        $self->status_bad_request( $c, message => 'invalid user_id' ), $c->detach
          unless Iota::Controller::Dados::int_validation( $self, @ids );

        $data_rs = $data_rs->search(
            {
                user_id => { 'in' => \@ids }
            }
        );
    }

    if ( exists $params->{city_id} ) {
        my @ids = split /,/, $params->{city_id};

        $self->status_bad_request( $c, message => 'invalid city_id' ), $c->detach
          unless Iota::Controller::Dados::int_validation( $self, @ids );

        $data_rs = $data_rs->search(
            {
                city_id => { 'in' => \@ids }
            }
        );
    }

    if ( exists $params->{variable_id} ) {
        my @ids = split /,/, $params->{variable_id};

        $self->status_bad_request( $c, message => 'invalid variable_id' ), $c->detach
          unless Iota::Controller::Dados::int_validation( $self, @ids );

        $data_rs = $data_rs->search(
            {
                variable_id => { 'in' => \@ids }
            }
        );
    }

    if ( exists $params->{valid_from} ) {
        my @dates = split /,/, $params->{valid_from};

        $self->status_bad_request( $c, message => 'invalid date format' ), $c->detach
          unless Iota::Controller::Dados::date_validation( $self, @dates );

        $data_rs = $data_rs->search(
            {
                valid_from => { 'in' => \@dates }
            }
        );
    }

    if ( exists $params->{valid_from_begin} ) {

        $self->status_bad_request( $c, message => 'invalid date format' ), $c->detach
          unless Iota::Controller::Dados::date_validation( $self, $params->{valid_from_begin} );

        $data_rs = $data_rs->search(
            {
                valid_from => { '>=' => $params->{valid_from_begin} }
            }
        );
    }

    if ( exists $params->{valid_from_end} ) {

        $self->status_bad_request( $c, message => 'invalid date format' ), $c->detach
          unless Iota::Controller::Dados::date_validation( $self, $params->{valid_from_end} );

        $data_rs = $data_rs->search(
            {
                '-and' => {
                    valid_from => { '<=' => $params->{valid_from_end} }
                }
            }
        );
    }

    while ( my $row = $data_rs->next ) {
        $row->{period}     = $self->_period_pt( $row->{period} );
        $row->{valid_from} = $self->ymd2dmy( $row->{valid_from} );
        push @objs, $row;
    }

    $self->status_ok( $c, entity => { data => \@objs } );
}

##################################################

for my $chain (
    qw/institute_load network_cidade cidade_regiao network_indicator network_indicador cidade_regiao_indicator/) {
    for my $tipo (qw/csv json xls xml/) {
        eval( "
            sub chain_${chain}_${tipo} : Chained('/$chain') : PathPart('variaveis.$tipo') : CaptureArgs(0) {
                my ( \$self, \$c ) = \@_;
                \$c->stash->{type} = '$tipo';
            }

            sub chain_${chain}_${tipo}_check : Chained('/$chain') : PathPart('variaveis.$tipo.checksum') : CaptureArgs(0) {
                my ( \$self, \$c ) = \@_;
                \$c->stash->{type} = '$tipo.check';
            }

            sub render_${chain}_${tipo} : Chained('chain_${chain}_${tipo}') : PathPart('') : Args(0) {
                my ( \$self, \$c ) = \@_;
                \$self->_download(\$c);
            }

            sub render_${chain}_${tipo}_check : Chained('chain_${chain}_${tipo}_check') : PathPart('') : Args(0) {
                my ( \$self, \$c ) = @_;
                \$self->_download(\$c);
            }
        " );
    }
}
1;

