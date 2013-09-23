package Iota::Controller::API::UserPublic::Indicator;

use Moose;

use Iota::IndicatorFormula;
use Iota::IndicatorChart::PeriodAxis;

use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/userpublic/object') : PathPart('indicator') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    my @user_ids = ( $c->stash->{user_obj}->id );
    my $country  = eval { $c->stash->{user_obj}->city->country_id };
    my @networks = $c->stash->{user_obj}->networks->all;
    if (@networks) {
        my $rs = $c->model('DB::User')->search(
            {
                'network_users.network_id' => [ map { $_->id } @networks ],
                city_id                    => undef
            },
            { join => 'network_users' }
        );
        while ( my $u = $rs->next ) {
            push @user_ids, $u->id;
        }
    }

    $c->stash->{collection} = $c->model('DB::Indicator')->search(
        {
            '-or' => [
                { visibility_level => 'public' },
                { visibility_level => 'country', visibility_country_id => $country },
                { visibility_level => 'private', visibility_user_id => { 'in' => \@user_ids } },
                { visibility_level => 'restrict', 'indicator_user_visibilities.user_id' => { 'in' => \@user_ids } },
            ]
        },
        { join => ['indicator_user_visibilities'] }
    );

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $self->status_bad_request( $c, message => 'invalid.argument' ), $c->detach
      unless $id =~ /^[0-9]+$/;

    $c->stash->{indicator} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
    $c->stash->{indicator_obj} = $c->stash->{indicator}->next;

    $c->detach('/error_404') unless $c->stash->{indicator_obj};

}

sub all_variable : Chained('/api/userpublic/base') : PathPart('indicator/variable') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

sub all_variable_GET {
    my ( $self, $c ) = @_;

    my $controller = $c->controller('API::Indicator');
    $controller->all_variable_GET($c);
}

sub indicator : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

sub indicator_GET {
    my ( $self, $c ) = @_;

    $c->stash->{object} = $c->stash->{indicator};
    my $controller = $c->controller('API::Indicator');
    $controller->indicator_GET($c);

    my $indicator = $c->stash->{indicator_ref};
    my $conf = $indicator->user_indicator_configs->search( { user_id => $c->stash->{user_id} } )->next;

    if ($conf) {
        $c->stash->{rest}{user_indicator_config} = {
            technical_information => $conf->technical_information,
            hide_indicator        => $conf->hide_indicator
        };
    }
}

sub resumo : Chained('base') : PathPart('') : Args( 0 ) : ActionClass('REST') { }

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
    my $max_periodos = $c->req->params->{number_of_periods} || 4;
    my $from_date = $c->req->params->{from_date};

    $c->forward('/institute_load');
    eval {
        my $user_id   = $c->stash->{user_obj}->id;
        my $institute = $c->stash->{user_obj}->institute;

        my @hide_indicator =
          map { $_->indicator_id }
          $c->stash->{user_obj}->user_indicator_configs->search( { hide_indicator => 1 } )->all;

        my $rs = $c->stash->{collection}->search(
            {
                #'indicator_network_configs_one.network_id' => [ undef, map { $_->id } @{ $c->stash->{networks} } ],
                'me.id' => { '-not_in' => \@hide_indicator }
            },
            { prefetch => [ 'indicator_variations', 'axis' ] }
        );

        my $rs_confs = $c->model('DB::IndicatorNetworkConfig')->search(
            {
                'me.indicator_id' => { '-not_in' => \@hide_indicator },
                'me.network_id'   => $c->stash->{network}->id
            },
            {
                result_class => 'DBIx::Class::ResultClass::HashRefInflator'
            }
        );
        my $indicator_conf = {};
        while ( my $r = $rs_confs->next ) {
            $indicator_conf->{ $r->{indicator_id} } = $r;
        }

        my $active_value = exists $c->req->params->{active_value} ? $c->req->params->{active_value} : 1;

        my $periods_begin = {};
        my $indicators    = {};
        while ( my $indicator = $rs->next ) {
            $indicators->{ $indicator->period }{ $indicator->id } = $indicator;

            if ( !exists $periods_begin->{ $indicator->period } ) {
                $periods_begin->{ $indicator->period } =
                  $c->model('DB')->schema->voltar_periodo( $from_date, $indicator->period, $max_periodos )
                  ->{voltar_periodo};
            }
        }

        while ( my ( $periodo, $from_this_date ) = each %$periods_begin ) {

            my $custom_axis  = {};
            my $user_axis_rs = $c->model('DB::UserIndicatorAxisItem')->search(
                {
                    'me.indicator_id'             => { 'in' => [ keys %{ $indicators->{$periodo} } ] },
                    'user_indicator_axis.user_id' => $user_id,
                },
                {
                    prefetch => 'user_indicator_axis',
                    order_by => [ 'me.indicator_id', 'me.position' ]
                }
            );
            while ( my $row = $user_axis_rs->next ) {
                push @{ $custom_axis->{ $row->indicator_id } }, $row->user_indicator_axis->name;
            }

            my $values_rs = $c->model('DB::IndicatorValue')->search(
                {
                    'me.indicator_id' => { 'in' => [ keys %{ $indicators->{$periodo} } ] },
                    'me.user_id'      => $user_id,
                    'me.valid_from'   => {
                        '>=' => $from_this_date,

                        ( '<=' => $from_date ) x !!$from_date
                    },

                    'me.region_id'    => $c->req->params->{region_id},
                    'me.active_value' => $active_value
                }
            )->as_hashref;
            my $indicator_values = {};

            while ( my $row = $values_rs->next ) {
                $indicator_values->{ $row->{indicator_id} }{ $row->{valid_from} }{ $row->{variation_name} } = [
                    $row->{value}    #, $row->{sources} TODO usar a fonte no retorno?
                ];
            }

            while ( my ( $indicator_id, $indicator ) = each %{ $indicators->{$periodo} } ) {
                my $item = {};
                while ( my ( $from, $variations ) = each %{ $indicator_values->{$indicator_id} } ) {

                    $item->{$from}{nome} = Iota::IndicatorChart::PeriodAxis::get_label_of_period( $from, $periodo );

                    # nao eh variado
                    if ( exists $variations->{''} ) {

                        $item->{$from}{valor} = $variations->{''}[0];

                    }
                    else {
                        # TODO ler do indicador qual o totalization_method do indicador e fazer conforme isso
                        my $sum = undef;
                        foreach my $variation ( keys %$variations ) {
                            $sum ||= 0;

                            $item->{$from}{variations}{$variation} = { value => $variations->{$variation}[0] };
                            $sum += $variations->{$variation}[0];
                        }
                        $item->{$from}{valor} = $sum;

                        # gera novamente na ordem e com as variacoes que nao estao salvas
                        my @variations;
                        foreach my $var ( sort { $a->order <=> $b->order } $indicator->indicator_variations->all ) {
                            push @variations,
                              {
                                name  => $var->name,
                                value => $item->{$from}{variations}{ $var->name }{value}
                              };
                        }
                        $item->{$from}{variations} = \@variations;

                    }

                }

                my @group_list = ();
                if ( exists $custom_axis->{$indicator_id} ) {
                    push @group_list, $indicator->axis->name
                      unless $institute->bypass_indicator_axis_if_custom;

                    push @group_list, @{ $custom_axis->{$indicator_id} };
                }
                else {
                    push @group_list, $indicator->axis->name;
                }

                foreach my $axis (@group_list) {
                    my $config = $indicator_conf->{ $indicator->id };

                    push(
                        @{ $ret->{resumos}{$axis}{$periodo}{indicadores} },
                        {
                            name           => $indicator->name,
                            formula        => $indicator->formula,
                            formula_human  => $indicator->formula_human,
                            name_url       => $indicator->name_url,
                            explanation    => $indicator->explanation,
                            variable_type  => $indicator->variable_type,
                            network_config => $config
                            ? {
                                unfolded_in_home => $config->{unfolded_in_home},
                                network_id       => $config->{network_id}
                              }
                            : { unfolded_in_home => 0 },
                            id => $indicator_id,

                            valores => $item
                        }
                    );
                }

            }
        }

        while ( my ( $axis, $periodos ) = each %{ $ret->{resumos} } ) {

            while ( my ( $periodo, $ind_info ) = each %{$periodos} ) {
                my $indicadores = $ind_info->{indicadores};

                # procura pelas ultimas N periodos de novo, so que consideranto todos os
                # indicadores duma vez
                my $datas = {};
                my @datas_ar;
                foreach my $in (@$indicadores) {
                    $datas->{$_}{nome} = $in->{valores}{$_}{nome} for ( keys %{ $in->{valores} } );

                    $datas->{$_}{variations} = $in->{valores}{$_}{variations} for ( keys %{ $in->{valores} } );

                }

                # tira data dos valores vazios
                # inseridos no primeiro loop do indicador (caso ele apareca em dois grupos)
                delete $datas->{''};

                my $i = $max_periodos;
                foreach my $data ( sort { $b cmp $a } keys %{$datas} ) {
                    last if $i <= 0;
                    $datas_ar[ --$i ] = {
                        data => $data || '',
                        nome => Iota::IndicatorChart::PeriodAxis::get_label_of_period( $data, $periodo )
                    };
                }

                # pronto, agora @datas ja tem a lista correta e na ordem!
                foreach my $in (@$indicadores) {

                if ($in->{id} == 111){
                    use DDP; p $in;

                }

                    my @valores;
                    foreach my $data (@datas_ar) {
                        unless ( exists $data->{data} ) {
                            push @valores, '-';
                            next;
                        }
                        push @valores,
                          exists $in->{valores}{ $data->{data} }{valor} ? $in->{valores}{ $data->{data} }{valor} : '-';
                    }

                    my @variacoes;
                    my $defined = 0;
                    foreach my $data (@datas_ar) {
                        unless ( defined $data->{data} ) {
                            push @variacoes, '-';
                            next;
                        }

                        if ( exists $in->{valores}{ $data->{data} }{variations} ) {
                            $defined++;
                            push @variacoes, $in->{valores}{ $data->{data} }{variations};
                        }
                        else {
                            push @variacoes, undef;
                        }
                    }
                    $in->{variacoes} = \@variacoes if $defined;

                    $in->{valores} = \@valores;

                }
                $ind_info->{datas} = \@datas_ar;
            }
        }
    };

    if ($@) {
        $self->status_bad_request( $c, message => "$@", );
    }
    else {
        $self->status_ok( $c, entity => $ret );
    }
}

sub indicator_status : Chained('base') : PathPart('status') : Args( 0 ) : ActionClass('REST') { }

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

        my @hide_indicator =
          map { $_->indicator_id }
          $c->stash->{user_obj}->user_indicator_configs->search( { hide_indicator => 1 } )->all;

        my $rs = $c->stash->{collection}->search(
            {
                'me.id' => { '-not_in' => \@hide_indicator }
            }
        );

        my @indicator_ids = map { $_->{id} } $rs->as_hashref->all;
        my $user_id = $c->stash->{user_obj}->id;

        my $region_tb = exists $c->req->params->{region_id} ? 'Region' : '';
        my $region_id = $c->req->params->{region_id};

        # % em relacao a meta # WARNING non-sense for a while.
        my $rs_x = $c->model('DB')->resultset( 'ViewIndicatorGoalRatio' . $region_tb )->search_rs(
            undef,
            {
                'bind' => [ $user_id, ( $c->req->params->{region_id} ) x !!$region_tb ],
                result_class => 'DBIx::Class::ResultClass::HashRefInflator'
            }
        );
        my $ratios = {};
        while ( my $f = $rs_x->next ) {
            $ratios->{ delete $f->{id} } = $f;
        }

        # status
        $rs = $c->model('DB')->resultset( 'ViewIndicatorStatus' . $region_tb )->search_rs(
            undef,
            {
                bind =>

                  # com regiao
                  $region_tb
                ? [
                    [ { sqlt_datatype => 'int[]' }, \@indicator_ids ],
                    $user_id, $region_id, $user_id, $user_id, $region_id,
                    $user_id, $region_id, $user_id, $region_id
                  ]
                :    # sem regiao
                  [
                    [ { sqlt_datatype => 'int[]' }, \@indicator_ids ],
                    $user_id, $user_id, $user_id, $user_id, $user_id

                  ],
                result_class => 'DBIx::Class::ResultClass::HashRefInflator'
            }
        );

        my $total_nao_preenchido = 0;
        my $total_algum_valor    = 0;
        my $total_current        = 0;
        while ( my $f = $rs->next ) {
            my $id = $f->{id};

            $f->{ratio} = $ratios->{$id} if exists $ratios->{$id};

            push @{ $ret->{status} }, $f;
            $total_nao_preenchido++ if $f->{without_data};
            $total_algum_valor++    if $f->{has_data};
            $total_current++        if $f->{has_current};
        }

        my $total = @{ $ret->{status} };
        $ret->{totals} = {
            has_data_perc     => $total_algum_valor / $total,
            without_data_perc => $total_nao_preenchido / $total,
            has_current_perc  => $total_current / $total,

        } if $total > 0;

    };

    if ($@) {
        $self->status_bad_request( $c, message => "$@", );
    }
    else {
        $self->status_ok( $c, entity => $ret );
    }
}

1;

