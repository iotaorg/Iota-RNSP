package Iota::Controller::API::UserPublic::Indicator;

use Moose;

use  Iota::IndicatorFormula;
use Iota::IndicatorChart::PeriodAxis;

use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );


sub base : Chained('/api/userpublic/object') : PathPart('indicator') : CaptureArgs(0) {
    my ( $self, $c, $id ) = @_;

    $c->stash->{collection} = $c->model('DB::Indicator')->search(
        {
            'indicator_network_configs.network_id' => [$c->stash->{network}->id, undef]
        }, { prefetch => ['indicator_network_configs'] }
    );
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
  my ( $self, $c, $id ) = @_;

  $c->stash->{indicator} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
  $c->stash->{indicator_obj} = $c->stash->{indicator}->next;

  $c->detach('/error_404') unless $c->stash->{indicator_obj};


}

sub all_variable: Chained('/api/userpublic/base') : PathPart('indicator/variable') : Args(0) : ActionClass('REST') {
  my ( $self, $c ) = @_;

}

sub all_variable_GET {
    my ( $self, $c ) = @_;

    my $controller = $c->controller('API::Indicator');
    $controller->all_variable_GET( $c );
}

sub indicator : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
  my ( $self, $c ) = @_;

}

sub indicator_GET {
    my ( $self, $c ) = @_;

    $c->stash->{object} = $c->stash->{indicator};
    my $controller = $c->controller('API::Indicator');
    $controller->indicator_GET( $c );
}

sub resumo :Chained('base') : PathPart('') : Args( 0 ) : ActionClass('REST') {}


=pod


"pagina home" isso gera a maior parte dos dados da home de uma rede.

GET /api/public/user/$id/indicator

retorna os valores dos ultimos 4 periodos de cada indicator

\ {
    resumos:  {
        weekly:  {
            datas      :  [
                [0] {
                    data:  "2012-01-08",
                    nome:  "semana 1"
                },
                [1] {
                    data:  "2012-01-15",
                    nome:  "semana 2"
                },
                [2] {
                    data:  "2012-01-22",
                    nome:  "semana 3"
                },
                [3] {
                    data:  "2012-01-29",
                    nome:  "semana 4"
                }
            ],
            indicadores:  [
                [0] {
                    explanation:  "explanation",
                    formula    :  "$590+ $591",
                    name       :  "Temperatura maxima da semana: SP",
                    valores    :  [
                        [0] 30,
                        [1] 32,
                        [2] 36,
                        [3] 37
                    ]
                }
            ]
        },
        yearly:  {
            datas      :  [
                [0] {
                    data:  "2009-01-01",
                    nome:  "ano 2009"
                },
                [1] {
                    data:  "2010-01-01",
                    nome:  "ano 2010"
                },
                [2] {
                    data:  "2011-01-01",
                    nome:  "ano 2011"
                },
                [3] {
                    data:  "2012-01-01",
                    nome:  "ano 2012"
                }
            ],
            indicadores:  [
                [0] {
                    explanation:  "explanation",
                    id         : 123,
                    formula    :  "$592",
                    name       :  "outra coisa por ano: SP",
                    valores    :  [
                        [0] "-",
                        [1] 28.6,
                        [2] 25.8,
                        [3] 23.5
                    ]
                },
                [1] {
                    explanation:  "explanation",
                    formula    :  "$593",
                    name       :  "111: SP",
                    valores    :  [
                        [0] 246.8,
                        [1] 245.8,
                        [2] 222.5,
                        [3] "-"
                    ]
                }
            ]
        }
    }
}

=cut

sub resumo_GET {
    my ( $self, $c ) = @_;
    my $ret;
    my $max_periodos = 4;
    eval {
        my $rs = $c->stash->{collection};

        my $user_axis_rs = $c->model('DB::UserIndicatorAxisItem')->search({

            'user_indicator_axis.user_id' => $c->stash->{user_obj}->id

        }, {
            join => 'user_indicator_axis',
        });


        while (my $indicator = $rs->next){

            my $indicator_formula = new Iota::IndicatorFormula(
                formula => $indicator->formula,
                schema => $c->model('DB')->schema
            );

            my @indicator_variations;
            my @indicator_variables;
            if ($indicator->indicator_type eq 'varied'){
                @indicator_variables  = $indicator->indicator_variables_variations->all;
                if ($indicator->dynamic_variations) {
                    @indicator_variations = $indicator->indicator_variations->search({
                        user_id => [$c->stash->{user_obj}->id, $indicator->user_id]
                    }, {order_by=>'order'})->all;
                }else{
                    @indicator_variations = $indicator->indicator_variations->search(undef, {order_by=>'order'})->all;
                }
            }


            my $rs = $c->model('DB')->resultset('Variable')->search_rs({
                'me.id' => [$indicator_formula->variables],
            } );

            my $res;

            my $valid_from;
            my $perido;
            my $variaveis = 0;
            while (my $row = $rs->next){
                if (!$valid_from){
                    $valid_from = $c->model('DB')->schema->voltar_periodo(
                        $row->values->get_column('valid_from')->max(),
                        $row->period, $max_periodos)->{voltar_periodo};
                    $perido = $row->period;
                }
                next unless $valid_from;


                my $rsx = $row->values->search({
                    'me.valid_from' => {'>' => $valid_from},
                    'me.user_id'    => $c->stash->{user_obj}->id

                })->as_hashref;
                while (my $value = $rsx->next){
                    $res->{$value->{valid_from}}{$value->{variable_id}} = $value->{value};
                }
                $variaveis++;
            }
            $perido = 'yearly' if $variaveis == 0;
            next unless $perido;

            my $item = {};
            foreach my $from (keys %{$res}){
                $item->{$from}{nome} = Iota::IndicatorChart::PeriodAxis::get_label_of_period( $from, $perido);

                my $undef = 0;
                map {$undef++ unless defined $_} values %{$res->{$from}};

                if ($undef == 0 && keys %{$res->{$from}} == $variaveis){

                    if (@indicator_variables && @indicator_variations){

                        my $vals = {};

                        for my $variation (@indicator_variations){

                            my $rs = $variation->indicator_variables_variations_values->search({
                                valid_from => $from
                            })->as_hashref;
                            while (my $r = $rs->next){
                                next unless defined $r->{value};
                                $vals->{$r->{indicator_variation_id}}{$r->{indicator_variables_variation_id}} = $r->{value}
                            }

                            my $qtde_dados = keys %{$vals->{$variation->id}};

                            unless ($qtde_dados == @indicator_variables){
                                $item->{$from}{variations}{$variation->id} = {
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
                                V => $res->{$from},
                                N => $vals->{$variation_id},
                            );

                            $item->{$from}{variations}{$variation_id} = {
                                value => $val
                            };
                            $sum += $val;
                        }
                        $item->{$from}{valor} = $sum;

                        my @variations;
                        # corre na ordem
                        foreach my $var (@indicator_variations){
                            push @variations, {
                                name  => $var->name,
                                value => $item->{$from}{variations}{$var->id}{value}
                            };
                        }
                        $item->{$from}{variations} = \@variations;

                    }else{


                        if ($indicator->formula =~ /#\d/){
                            $item->{$from}{valor} = 'ERR#';
                        }else{
                            $item->{$from}{valor} = $indicator_formula->evaluate(%{$res->{$from}});
                        }
                    }

                }else{
                    $item->{$from}{valor} = '-';
                }
            }
            my @axis_list = ($indicator->axis->name);
            my @grupos = $user_axis_rs->search({
                indicator_id => $indicator->id
            });
            if (@grupos){
                @axis_list = map {$_->user_indicator_axis->name} @grupos;
            }
            foreach my $axis (@axis_list){
                my ($config) = $indicator->indicator_network_configs->all;

                push(@{$ret->{resumos}{$axis}{$perido}{indicadores}}, {
                    name        => $indicator->name,
                    formula     => $indicator->formula,
                    name_url    => $indicator->name_url,
                    explanation => $indicator->explanation,
                    network_config => $config ? {
                        unfolded_in_home => $config->unfolded_in_home,
                        network_id       => $config->network_id
                    } : {
                        unfolded_in_home => 0
                    },
                    id          => $indicator->id,

                    valores     => $item
                });
            }
        }


        while( my ($axis, $periodos) = each %{$ret->{resumos}}){

            while( my ($periodo, $ind_info) = each %{$periodos}){
                # ja passou por aqui

                my $indicadores = $ind_info->{indicadores};


                # procura pelas ultimas N periodos de novo, so que consideranto todos os
                # indicadores duma vez
                my $datas = {};
                my @datas_ar;
                foreach my $in (@$indicadores){
                    $datas->{$_}{nome} = $in->{valores}{$_}{nome}
                        for (keys %{$in->{valores}} );

                    $datas->{$_}{variations} = $in->{valores}{$_}{variations}
                        for (keys %{$in->{valores}} );

                }
                # tira data dos valores vazios
                # inseridos no primeiro loop do indicador (caso ele apareca em dois grupos)
                delete $datas->{''};

                my $i     = $max_periodos;
                foreach my $data (sort {$b cmp $a} keys %{$datas}){
                    last if $i <= 0;
                    $datas_ar[--$i] = {
                        data => $data||'',
                        nome => $datas->{$data}{nome}
                    };
                }

                # pronto, agora @datas ja tem a lista correta e na ordem!
                foreach my $in (@$indicadores){
                    my @valores;
                    foreach my $data (@datas_ar){
                        unless (exists $data->{data}){
                            push @valores, '-';
                            next;
                        }
                        push @valores, exists $in->{valores}{$data->{data}}{valor} ?
                            $in->{valores}{$data->{data}}{valor} : '-';
                    }

                    my @variacoes;
                    my $defined = 0;
                    foreach my $data (@datas_ar){
                        unless (defined $data->{data}){
                            push @variacoes, '-';
                            next;
                        }

                        if (exists $in->{valores}{$data->{data}}{variations}){
                            $defined++ ;
                            push @variacoes, $in->{valores}{$data->{data}}{variations};
                        }else{
                            push @variacoes, undef;
                        }
                    }
                    $in->{variacoes} = \@variacoes if $defined;

                    $in->{valores}  = \@valores;

                }
                $ind_info->{datas} = \@datas_ar;
            }
        }
    };

    if ($@){
        $self->status_bad_request(
            $c,
            message => "$@",
        );
    }else{
        $self->status_ok(
            $c,
            entity => $ret
        );
    }
}


sub indicator_status:Chained('base') : PathPart('status') : Args( 0 ) : ActionClass('REST') {}

=pod


GET /api/public/user/$id/indicator/status

Retorna o status de prenchimento dos indicadores

\ {
    status:  [
        {
            id: 123
            has_data=
            has_current=
            without_data=
        },
    ]
}

=cut

sub indicator_status_GET {
    my ( $self, $c ) = @_;
    my $ret;
    my $ultimos = {};
    eval {
        my $rs = $c->stash->{collection};

        while (my $indicator = $rs->next){
            my $indicator_formula = new Iota::IndicatorFormula(
                formula => $indicator->formula,
                schema => $c->model('DB')->schema
            );

            my $rs = $c->model('DB')->resultset('Variable')->search_rs({
                'me.id' => [$indicator_formula->variables],
            } );


            my $variaveis = 0;
            my $ultima_data;

            my $outros_periodos = {};
            my $ultimo_periodo = {};

            while (my $row = $rs->next){
                # ultima data do periodo geral
                unless (exists $ultimos->{$row->period}){
                    my $ret = $c->model('DB')->schema->ultimo_periodo($row->period);
                    $ultimos->{$row->period} = $ret->{ultimo_periodo};
                }
                $ultima_data = $ultimos->{$row->period};


                my $rsx = $row->values->search({
                    'me.user_id'    => $c->stash->{user_obj}->id
                })->as_hashref;

                while (my $value = $rsx->next){
                    if (($value->{value} || $value->{value} eq '0') && $value->{valid_from} eq $ultima_data){
                        $ultimo_periodo->{$value->{valid_from}}++;
                    }elsif($value->{value} || $value->{value} eq '0'){
                        $outros_periodos->{$value->{valid_from}}++;
                    }

                }
                $variaveis++;
            }
            while(my($k, $v) = each %$outros_periodos){
                delete $outros_periodos->{$k} unless $outros_periodos->{$k} == $variaveis;
            }

            my $has_current        = ($ultima_data && exists $ultimo_periodo->{$ultima_data} && $ultimo_periodo->{$ultima_data} == $variaveis) ? 1 : 0;
            if ($variaveis && !$has_current && scalar(keys %$outros_periodos) == 0){
                push @{$ret->{status}}, {
                    id           => $indicator->id,
                    without_data => 1,
                    has_data     => 0,
                    has_current  => 0
                };
            }else{
                my @indicator_variations;
                my @indicator_variables;
                if ($indicator->indicator_type eq 'varied'){
                    @indicator_variables  = $indicator->indicator_variables_variations->all;
                    if ($indicator->dynamic_variations) {
                        @indicator_variations = $indicator->indicator_variations->search({
                            user_id => [$c->stash->{user_obj}->id, $indicator->user_id]
                        }, {order_by=>'order'})->all;
                    }else{
                        @indicator_variations = $indicator->indicator_variations->search(undef, {order_by=>'order'})->all;
                    }
                }

                if ($variaveis == 0){
                    my $ret = $c->model('DB')->schema->ultimo_periodo('yearly');
                    $ultima_data = $ret->{ultimo_periodo};
                }


                if (@indicator_variables && @indicator_variations){

                    my @datas = $variaveis == 0
                        ? $self->_get_values_dates(\@indicator_variations)
                        : (
                            ($has_current ? (  $ultima_data ) : ()),
                            keys %$outros_periodos
                        );
                    $outros_periodos = {};
                    $has_current     = 0;

                    foreach my $from (@datas){
                        my $vals = {};

                        my $completa = 1;

                        for my $variation (@indicator_variations){

                            my $rs = $variation->indicator_variables_variations_values->search({
                                valid_from => $from
                            })->as_hashref;
                            while (my $r = $rs->next){
                                next unless defined $r->{value};
                                $vals->{$r->{indicator_variation_id}}{$r->{indicator_variables_variation_id}} = $r->{value}
                            }

                            my $qtde_dados = keys %{$vals->{$variation->id}};

                            if ($qtde_dados != @indicator_variables){
                                $completa = 0;
                                last;
                            }
                        }

                        if ($completa){
                            if ( $from eq $ultima_data ){
                                $has_current = 1;
                            }else{
                                $outros_periodos->{$from} = 1;
                            }
                        }
                    }

                }

                push @{$ret->{status}}, {
                    id =>  $indicator->id,
                    has_current        => $has_current,
                    has_data           => (keys %$outros_periodos > 0) ? 1 : 0,
                    without_data       => (!$has_current && (keys %$outros_periodos == 0)) ? 1 : 0
                };
            }
        }
    };

    if ($@){
        $self->status_bad_request(
            $c,
            message => "$@",
        );
    }else{
        $self->status_ok(
            $c,
            entity => $ret
        );
    }
}

sub _get_values_dates {
    my ($self, $variations) = @_;

    my %dates;

    foreach my $variation (@$variations){

        my @dates = $variation->indicator_variables_variations_values->search(undef, {
            select => [qw/valid_from/],
            as => [qw/valid_from/],
            group_by => [qw/valid_from/]
        })->as_hashref->all;
        map {$dates{$_->{valid_from}} = 1} @dates;

    }

    return keys %dates;
}

1;

