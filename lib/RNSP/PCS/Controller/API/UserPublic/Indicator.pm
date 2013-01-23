package RNSP::PCS::Controller::API::UserPublic::Indicator;

use Moose;

use  RNSP::IndicatorFormula;
use RNSP::IndicatorChart::PeriodAxis;

use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/userpublic/object') : PathPart('indicator') : CaptureArgs(0) {
  my ( $self, $c, $id ) = @_;
  $c->stash->{collection} = $c->model('DB::Indicator');
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
  my ( $self, $c, $id ) = @_;

  $c->stash->{indicator} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
  $c->stash->{indicator_obj} = $c->stash->{indicator}->next;

  $c->detach('/error_404') unless $c->stash->{indicator_obj};


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

        while (my $indicator = $rs->next){

            my $indicator_formula = new RNSP::IndicatorFormula(
                formula => $indicator->formula,
                schema => $c->model('DB')->schema
            );

            my @indicator_variations;
            my @indicator_variables;
            if ($indicator->indicator_type eq 'varied'){
                @indicator_variables  = $indicator->indicator_variables_variations->all;
                if ($indicator->dynamic_variations) {
                    @indicator_variations = $indicator->indicator_variations->search({
                        user_id => $c->stash->{user_obj}->id
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
            next unless $perido;

            my $item = {};
            foreach my $from (keys %{$res}){
                $item->{$from}{nome} = RNSP::IndicatorChart::PeriodAxis::get_label_of_period( $from, $perido);

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
                        my $sum = 0;
                        foreach my $variation_id (keys %$vals){

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

                        die('Indicador sem dados de varied.') if $indicator->formula =~ /#\d/;

                        $item->{$from}{valor} = $indicator_formula->evaluate(%{$res->{$from}});
                    }

                }else{
                    $item->{$from}{valor} = '-';
                }
            }
            my $axis = $indicator->axis->name;
            push(@{$ret->{resumos}{$axis}{$perido}{indicadores}}, {
                name        => $indicator->name,
                formula     => $indicator->formula,
                name_url    => $indicator->name_url,
                explanation => $indicator->explanation,
                id          => $indicator->id,

                valores     => $item
            });
        }


        while( my ($axis, $periodos) = each %{$ret->{resumos}}){
            while( my ($periodo, $ind_info) = each %{$periodos}){
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

                my $i     = $max_periodos;
                foreach my $data (sort {$b cmp $a} keys %{$datas}){
                    last if $i <= 0;
                    $datas_ar[--$i] = {
                        data => $data,
                        nome => $datas->{$data}{nome}
                    };
                }
                # pronto, agora @datas ja tem a lista correta e na ordem!
                foreach my $in (@$indicadores){


                    my @valores;
                    foreach my $data (@datas_ar){
                        push @valores, $in->{valores}{$data->{data}}{valor} ||'-';
                    }

                    my @variacoes;
                    my $defined = 0;
                    foreach my $data (@datas_ar){
                        $defined++ if exists $in->{valores}{$data->{data}}{variations};
                        push @variacoes, $in->{valores}{$data->{data}}{variations};
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
            ultimo_periodo: 1 ou 0,
            outros_periodos: 1 ou 0,
            completo_historico: 1 ou 0
            -- se ultimo_periodo E outros_periodos forem 0 nao tem nenhum dado
            -- se ultimo_periodo for 1 e outros_periodos for 0,
            -- nao ha dados apenas do ultimo periodo
            -- completo_historico so eh verdadeiro quando todos os periodos
            -- foram preenchidos ignorando o ultimo (se quiser saber se esta tudo completo, use completo_historico+ultimo_periodo==2)
        },
    ]
}

=cut

sub indicator_status_GET {
    my ( $self, $c ) = @_;
    my $ret;
    my $max_periodos = 4;
    my $ultimos = {};
    eval {
        my $rs = $c->stash->{collection};

        while (my $indicator = $rs->next){

            my $indicator_formula = new RNSP::IndicatorFormula(
                formula => $indicator->formula,
                schema => $c->model('DB')->schema
            );

            my $rs = $c->model('DB')->resultset('Variable')->search_rs({
                'me.id' => [$indicator_formula->variables],
            } );

            my $valid_from;
            my $perido;
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

                if (!$valid_from){
                    $valid_from = $c->model('DB')->schema->voltar_periodo(
                        $ultima_data,
                        $row->period, $max_periodos)->{voltar_periodo};
                    $perido = $row->period;
                }
                next unless $valid_from;


                my $rsx = $row->values->search({
                    'me.valid_from' => {'>' => $valid_from},
                    'me.user_id'    => $c->stash->{user_obj}->id

                })->as_hashref;

                while (my $value = $rsx->next){
                    if ($value->{value} && $value->{valid_from} eq $ultima_data){
                        $ultimo_periodo->{$value->{valid_from}}++;
                    }elsif($value->{value}){
                        $outros_periodos->{$value->{valid_from}}++;
                    }

                }
                $variaveis++;
            }
            # nenhuma variavel
            unless ($perido){
                push @{$ret->{status}}, {
                    id =>  $indicator->id,
                    ultimo_periodo => 0,
                    outros_periodos => 0,
                    completo_historico => 0
                };
                next;
            }

            while(my($k, $v) = each %$outros_periodos){
                delete $outros_periodos->{$k} unless $outros_periodos->{$k} == $variaveis;
            }

            push @{$ret->{status}}, {
                id =>  $indicator->id,
                ultimo_periodo     => (exists $ultimo_periodo->{$ultima_data} && $ultimo_periodo->{$ultima_data} == $variaveis) ? 1 : 0,
                outros_periodos    => (keys %$outros_periodos > 0) ? 1 : 0,
                completo_historico => (keys %$outros_periodos == $max_periodos - 1) ? 1 : 0,
            };

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

1;

