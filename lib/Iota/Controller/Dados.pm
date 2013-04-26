
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
use JSON::XS;
use Iota::IndicatorFormula;
use Text::CSV_XS;
use XML::Simple qw(:strict);
use Digest::MD5;



# download de todos os endpoints caem aqui
sub _download {
    my ( $self, $c ) = @_;

    my $network = $c->stash->{network};

    my $file = $network->name_url;
    $file .= '_' . $c->stash->{pais} . '_' . $c->stash->{estado} . '_' . $c->stash->{cidade}
                if $c->stash->{cidade};
    $file .= '_' .  $c->stash->{indicator}{name_url}
                if $c->stash->{indicator};
    $file .= '.' . $c->stash->{type};

    my $path = ($c->config->{downloads}{tmp_dir}||'/tmp') . '/' . lc $file;

    if (-e $path){
        # apaga o arquivo caso passe 12 horas
        my $epoch_timestamp = (stat($path))[9];
        unlink($path) if time() - $epoch_timestamp > 43200;
    }
    $self->_download_and_detach($c, $path) if -e $path;

    # procula pela cidade, se existir.
    my $cities = $c->model('DB::City')->as_hashref;

    $cities = $cities->search({
        pais     => lc $c->stash->{pais},
        uf       => uc $c->stash->{estado},
        name_uri => lc $c->stash->{cidade}
    }) if $c->stash->{cidade};

    $c->detach('/error_404') if $c->stash->{cidade} && !$cities->count;

    #my $role_id = $c->model('DB::Role')->search( {name => $c->stash->{find_role}})->next;
    #$c->detach('/error_404') unless $role_id;


    my @lines = (
        ['ID da cidade',
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
        ]
    );

    while(my $city = $cities->next){
        my $indicadores = $c->stash->{indicator}{id} ? {
            'me.id'     => $c->stash->{indicator}{id}
        } : undef;


        my $rs = $c->model('DB::Indicator')->search($indicadores, { prefetch => ['axis'] });
        while (my $indicator = $rs->next){

            my $user = $c->model('DB::User')->search({
                city_id => $city->{id},
                'me.active'  => 1,
                'me.network_id' => $network->id
            }, {  join  => 'user_roles'} )->as_hashref->next;
            $c->detach('/error_404') if $c->stash->{cidade} && !$user;
            next if !$user;

            my @indicator_variations;
            my @indicator_variables;
            if ($indicator->indicator_type eq 'varied'){

                if ($indicator->dynamic_variations) {
                    @indicator_variations = $indicator->indicator_variations->search({
                        user_id => [$user->{id}, $indicator->user_id]
                    }, {order_by=>'order'})->all;
                }else{
                    @indicator_variations = $indicator->indicator_variations->search(undef, {order_by=>'order'})->all;
                }

                @indicator_variables  = $indicator->indicator_variables_variations->all;
            }

            my $indicator_formula = new Iota::IndicatorFormula(
                formula => $indicator->formula,
                schema => $c->model('DB')->schema
            );

            my $rs = $c->model('DB')->resultset('Variable')->search_rs({
                'me.id' => [$indicator_formula->variables]
            });


            my $hash = {};
            my $tmp  = {};
            my $x = 0;
            my $period = 'yearly';
            while (my $row = $rs->next){
                $hash->{header}{$row->name} = $x;
                $hash->{id_nome}{$row->id} = $row->name;
                $period = $row->period;

                my @values = $row->values->search({
                    user_id => $user->{id}
                })->all;
                foreach my $value (@values){
                    push @{$tmp->{$value->valid_from}}, {
                        col           => $x,
                        varid         => $row->id,
                        varn          => $row->name,
                        value         => $value->value,
                    }
                }
                $x++;
            }


            my $definidos = scalar keys %{$hash->{header}};

            foreach my $begin (sort {$a cmp $b} keys %$tmp){

                my @order = sort {$a->{col} <=> $b->{col}} grep {exists $_->{col} && defined $_->{value}} @{$tmp->{$begin}};
                my $attrs = $c->model('DB')->resultset('UserIndicator')->search_rs({
                    user_id      => $user->{id},
                    valid_from   => $begin,
                    indicator_id => $indicator->id
                })->next;

                my $item = {};
                if ($attrs){
                    $item->{justification_of_missing_field} = $attrs->justification_of_missing_field;
                    $item->{goal} = $attrs->goal;
                }

                if ($definidos == scalar @order){

                    if (@indicator_variables && @indicator_variations){

                        my $vals = {};

                        for my $variation (@indicator_variations){

                            my $rs = $variation->indicator_variables_variations_values->search({
                                valid_from => $begin,
                                user_id    => $user->{id}
                            })->as_hashref;
                            while (my $r = $rs->next){
                                next unless defined $r->{value};
                                $vals->{$r->{indicator_variation_id}}{$r->{indicator_variables_variation_id}} = $r->{value}
                            }

                            my $qtde_dados = keys %{$vals->{$variation->id}};

                            unless ($qtde_dados == @indicator_variables){
                                $item->{variations}{$variation->id} = {
                                value => '-'
                                };

                                delete $vals->{$variation->id};
                            }
                        }

                        # TODO ler do indicador qual o totalization_method
                        my $sum = undef;
                        foreach my $variation_id (keys %$vals){
                            $sum ||= 0;

                            my $val = $indicator_formula->evaluate_with_alias(
                                V => {map { $_->{varid} => $_->{value} } @order},
                                N => $vals->{$variation_id},
                            );

                            $item->{variations}{$variation_id} = {
                                value => $val
                            };
                            $sum += $val;
                        }
                        $item->{formula_value} = $sum;

                        my @variations;
                        # corre na ordem
                        foreach my $var (@indicator_variations){
                            push @variations, {
                                name  => $var->name,
                                value => $item->{variations}{$var->id}{value}
                            };
                        }
                        $item->{variations} = \@variations;

                    }else{

                        if ($indicator->formula =~ /#\d/){
                                $item->{formula_value} = 'ERR#';
                        }else{

                            $item->{formula_value} = $indicator_formula->evaluate(
                                map { $_->{varid} => $_->{value} } @order
                            );
                        }
                    }

                }


                if (ref $item->{variations} eq 'ARRAY'){
                    foreach my $variacao(@{$item->{variations}}){
                        my @this_row = (
                            $city->{id},
                            $city->{name},
                            $indicator->axis->name,
                            $indicator->id,
                            $indicator->name,
                            $indicator->formula_human,
                            $indicator->goal,
                            $indicator->goal_explanation,
                            $indicator->goal_source,
                            $indicator->goal_operator,
                            $indicator->explanation,
                            $indicator->tags,
                            $indicator->observations,
                            $self->_period_pt($period),
                            $variacao->{name},
                            $self->ymd2dmy($begin),
                            $variacao->{value},
                            $item->{goal},
                            $item->{justification_of_missing_field}
                        );
                        push @lines, \@this_row;
                    }
                }else{
                    my @this_row = (
                        $city->{id},
                        $city->{name},
                        $indicator->axis->name,
                        $indicator->id,
                        $indicator->name,
                        $indicator->formula_human,
                        $indicator->goal,
                        $indicator->goal_explanation,
                        $indicator->goal_source,
                        $indicator->goal_operator,
                        $indicator->explanation,
                        $indicator->tags,
                        $indicator->observations,
                        $self->_period_pt($period),
                        '',
                        $self->ymd2dmy($begin),
                        $item->{formula_value},
                        $item->{goal},
                        $item->{justification_of_missing_field}
                    );
                    push @lines, \@this_row;
                }

            }

        }

    }

    eval{$self->lines2file($c, $path, \@lines)};
    if ($@){
        $path =~ s/\.check//;
        unlink($path);
        $path .= '.check';
        unlink($path);
        die $@;
    }
    $self->_download_and_detach($c, $path);
}

sub _period_pt {
    my ( $self, $period) = @_;

    return 'semanal' if $period eq 'weekly';
    return 'mensal' if $period eq 'monthly';
    return 'anual' if $period eq 'yearly';
    return 'decada' if $period eq 'decade';
    return 'diario' if $period eq 'daily';

    return $period; # outros nao usados
}

sub _add_variables{
    my ( $self, $c, $hash, $arr ) = @_;
    my @rows = $c->model('DB')->resultset('Variable')->as_hashref
        ->search(undef, {order_by => 'name'})
        ->all;
    my $i = scalar @$arr;
    foreach my $var (@rows){
        $hash->{$var->{id}} = $i++;
        push @$arr, $var->{name};
    }
}

sub _concate_variables {
    my ( $self, $c, $header, $values, $row ) = @_;

    my %id_val = map { $_->{varid} => $_->{value} } @$values;

    foreach my $id (sort { $header->{$a} <=> $header->{$b}  } keys %$header ){
        if (exists $id_val{$id}){
            push @$row, $id_val{$id};
        }else{
            push @$row, '';
        }
    }

}


sub ymd2dmy{
    my ( $self, $str) = @_;
    return "$3/$2/$1" if ($str =~ /(\d{4})-(\d{2})-(\d{2})/);
    return '';
}

sub lines2file {
    my ( $self, $c, $path, $lines ) = @_;

    $path =~ s/\.check//;

    open my $fh, ">:encoding(utf8)", $path or die "$path: $!";
    if ($path =~ /csv$/){
        my $csv = Text::CSV_XS->new ({ binary => 1, eol => "\r\n" }) or
        die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

        $csv->print ($fh, $_) for @$lines;

    }elsif ($path =~ /json$/){

        print $fh encode_json($lines);

    }elsif ($path =~ /xml$/){
        print $fh XMLout($lines, KeyAttr => { server => 'linhas' } );

    }else{
        die("not a valid format");
    }
    close $fh or die "$path: $!";


    open($fh, $path) or die "Can't open '$path': $!";
    binmode($fh);
    my $md5 = Digest::MD5->new;
    while (<$fh>) {
        $md5->add($_);
    }
    close($fh);

    open $fh, '>', "$path.check" or die "$path: $!";
    print $fh $md5->hexdigest;;



}

sub _download_and_detach {
    my ( $self, $c, $path ) = @_;

    if ($c->stash->{type} =~ /(json)/){
        $c->response->content_type('application/json; charset=UTF-8');
    }elsif ($c->stash->{type} =~ /(xml)/){
        $c->response->content_type('text/xml');
    }elsif ($c->stash->{type} =~ /(csv)/){
        $c->response->content_type('text/csv');
    }
    $c->response->headers->header('content-disposition' => "attachment;filename=dados.$1");

    open(my $fh, '<:raw', $path);
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

sub pref_dados_csv_check: Chained('/institute_load') : PathPart('indicadores.csv.checksum') : CaptureArgs(0) {
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

# network XML
sub pref_dados_xml : Chained('/institute_load') : PathPart('indicadores.xml') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml';
}

sub pref_dados_xml_check: Chained('/institute_load') : PathPart('indicadores.xml.checksum') : CaptureArgs(0) {
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

sub pref_dados_json_check: Chained('/institute_load') : PathPart('indicadores.json.checksum') : CaptureArgs(0) {
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

sub pref_dados_cidade_csv_check: Chained('/network_cidade') : PathPart('indicadores.csv.checksum') : CaptureArgs(0) {
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

# network XML
sub pref_dados_cidade_xml : Chained('/network_cidade') : PathPart('indicadores.xml') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml';
}

sub pref_dados_cidade_xml_check: Chained('/network_cidade') : PathPart('indicadores.xml.checksum') : CaptureArgs(0) {
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

sub pref_dados_cidade_json_check: Chained('/network_cidade') : PathPart('indicadores.json.checksum') : CaptureArgs(0) {
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

sub pref_dados_cidade_indicadorcsv_check: Chained('/network_indicator') : PathPart('dados.csv.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'csv.check';
}

sub down_pref_dados_cidade_indicadorcsv : Chained('pref_dados_cidade_indicadorcsv') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_dados_cidade_indicadorcsv_check : Chained('pref_dados_cidade_indicadorcsv_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# network XML
sub pref_dados_cidade_indicadorxml : Chained('/network_indicator') : PathPart('dados.xml') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml';
}

sub pref_dados_cidade_indicadorxml_check: Chained('/network_indicator') : PathPart('dados.xml.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml.check';
}

sub down_pref_dados_cidade_indicadorxml : Chained('pref_dados_cidade_indicadorxml') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_dados_cidade_indicadorxml_check : Chained('pref_dados_cidade_indicadorxml_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# network JSON
sub pref_dados_cidade_indicadorjson : Chained('/network_indicator') : PathPart('dados.json') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'json';
}

sub pref_dados_cidade_indicadorjson_check: Chained('/network_indicator') : PathPart('dados.json.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'json.check';
}

sub down_pref_dados_cidade_indicadorjson : Chained('pref_dados_cidade_indicadorjson') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_dados_cidade_indicadorjson_check : Chained('pref_dados_cidade_indicadorjson_check') : PathPart('') : Args(0) {
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

sub pref_indicador_csv_check: Chained('/network_indicador') : PathPart('dados.csv.checksum') : CaptureArgs(0) {
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

# network XML
sub pref_indicador_xml : Chained('/network_indicador') : PathPart('dados.xml') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml';
}

sub pref_indicador_xml_check: Chained('/network_indicador') : PathPart('dados.xml.checksum') : CaptureArgs(0) {
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

sub pref_indicador_json_check: Chained('/network_indicador') : PathPart('dados.json.checksum') : CaptureArgs(0) {
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


