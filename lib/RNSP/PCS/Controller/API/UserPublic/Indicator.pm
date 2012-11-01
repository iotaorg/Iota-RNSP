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

sub reusmo :Chained('base') : PathPart('') : Args( 0 ) : ActionClass('REST') {}


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

sub reusmo_GET {
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

                if (keys %{$res->{$from}} == $variaveis){

                    my $undef = 0;
                    map {$undef++ unless defined $_} values %{$res->{$from}};

                    $item->{$from}{valor} = $undef ? '-' : $indicator_formula->evaluate(%{$res->{$from}});
                }else{
                    $item->{$from}{valor} = '-';
                }
            }
            push(@{$ret->{resumos}{$perido}{indicadores}}, {
                name        => $indicator->name,
                formula     => $indicator->formula,
                name_url    => $indicator->name_url,
                explanation => $indicator->explanation,
                id          => $indicator->id,

                valores     => $item
            });
        }


        while( my ($periodo, $ind_info) = each %{$ret->{resumos}}){
            my $indicadores = $ind_info->{indicadores};
            # procura pelas ultimas N periodos de novo, so que consideranto todos os
            # indicadores duma vez
            my $datas = {};
            my @datas_ar;
            foreach my $in (@$indicadores){
                $datas->{$_}{nome} = $in->{valores}{$_}{nome}
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
                $in->{valores} = \@valores;
            }
            $ind_info->{datas} = \@datas_ar;
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

