package Iota::IndicatorData;

use Moose;
use JSON::XS;
use Iota::IndicatorFormula;
has schema => (
    is       => 'ro',
    isa      => 'Any',
    required => 1
);

our $DEBUG = 0;

sub upsert {
    my ( $self, %params ) = @_;
    my $ind_rs = $self->schema->resultset('Indicator')->search( { is_fake => 0 } );

    #use DDP;
    #p \%params if $DEBUG;

    #use DDP; p \%params if $DEBUG;
    # procura pelos indicadores enviados
    $ind_rs = $ind_rs->search( { id => { in => $params{indicators} } } )
      if exists $params{indicators};

    push @{ $params{regions_id} }, delete $params{region_id} if exists $params{region_id} && $params{region_id};

    my @indicators = $ind_rs->all;
    my @indicators_ids = map { $_->id } @indicators;
    return unless scalar @indicators;

    # procura por todas as variaveis que esses indicadores podem utilizar
    my @used_variables =
      $self->schema->resultset('IndicatorVariable')->search( { indicator_id => { in => \@indicators_ids } } )->all;

    my $variable_ids;
    my $indicator_variables;
    foreach my $var (@used_variables) {
        $variable_ids->{ $var->variable_id } = 1;
        push @{ $indicator_variables->{ $var->indicator_id } }, $var->variable_id;
    }

    # procura pelos valores salvos
    my $values_rs = $self->schema->resultset('VariableValue');
    $values_rs = $values_rs->search( { valid_from => $params{dates} } ) if exists $params{dates};

    $values_rs = $values_rs->search(
        {
            ( 'me.user_id' => $params{user_id} ) x !!exists $params{user_id},
            'me.variable_id' => { 'in' => [ keys %$variable_ids ] }
        }
    );
    my $period_values = {};

    my @upper_regions;

    my ( $user_vs_institute, $institutes_conf );
    if ( exists $params{regions_id} ) {

        my %region_by_lvl;


        my $uppers;
        my $rs = $self->schema->resultset('Region')->search(
            {
                id => { 'in' => $params{regions_id} }
            },
            { columns => [ 'id', 'depth_level', 'upper_region', 'name' ] }
        )->as_hashref;
        while ( my $r = $rs->next ) {
            push @{ $region_by_lvl{ $r->{depth_level} } }, $r->{id};

            $uppers->{ $r->{depth_level} }{ $r->{upper_region} }++ if $r->{upper_region} && $r->{upper_region} != $r->{id};
        }

        #use DDP; p \%region_by_lvl if $DEBUG;
        die("Can't upsert more than 1 depth_level at once. Please contact admin of the system.") if keys %region_by_lvl > 1;

        my ($region_level) = keys %region_by_lvl;

        @upper_regions = keys %{$uppers->{ $region_level } || {}};

        #use DDP; p "region_level $region_level" if $DEBUG;
        # se esta consolidando por região,
        # foi porque mudou alguma variavel, então, bora repassar os parametros pra lá!
        # existem regioes acima desta regiao.
        if (@upper_regions) {

            # FUNCTION compute_upper_regions(_ids integer[],
            #                                _var_ids integer[],
            #                                _variation_var_ids integer[],
            #                                dates date[],
            #                               _cur_level integer)
            # se enviado nulo, o parametro são considerados todas as variaveis ou leveis
            my $ret = $self->schema->compute_upper_regions(
                $region_by_lvl{$region_level},
                $params{variables_ids},
                $params{variables_variations_ids},
                $params{dates}, $region_level
            );
            if ( !$ret ) {
                print STDERR "\n\n\n$@\n\n\n";
            }

            #use DDP; p \@upper_regions if $DEBUG;

#use DDP; p [$self->schema->resultset('RegionVariableValue')->search({valid_from => $params{dates}}, {result_class => 'DBIx::Class::ResultClass::HashRefInflator'})->all] if $DEBUG;
#use DDP; do {p $ret;} if $DEBUG;

        }

        # procura pelos valores salvos naquela regiao
        my $where = {
            ( 'me.user_id' => $params{user_id} ) x !!exists $params{user_id},
            ( 'me.valid_from' => $params{dates} ) x !!exists $params{dates},

            'me.variable_id' => { 'in' => [ keys %$variable_ids ] },
            'me.region_id'   => { 'in' => $params{regions_id} },
        };

        my $rr_values_rs = $self->schema->resultset('RegionVariableValue')->search($where);

        my $inputed_values = {};

        # primeiro carrega todos os valores inputados pelos usuarios.
        $self->_get_values_periods_region(
            out => $inputed_values,
            rs  => (
                $rr_values_rs->search_rs(
                    {
                        generated_by_compute => undef
                    }
                )
            )
        );

        #use DDP; p $inputed_values if $region_level == 2 && $DEBUG;
        my $sum_values = {};

        # agora carrega todos os valores dos computadores.
        $self->_get_values_periods_region(
            out => $sum_values,
            rs  => (
                $rr_values_rs->search_rs(
                    {
                        generated_by_compute => 1
                    }
                )
            )
        );

        #use DDP; p $sum_values if $region_level == 2 && $DEBUG;

        # carrega a preferencia dos indicadores,
        # se eh pra ativar o valor falso se não existir soma
        # no mesmo ano.
        $institutes_conf = {
            map { $_->{id} => $_->{active_me_when_empty} } $self->schema->resultset('Institute')->search(
                undef,
                {
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator'
                }
            )->all
        };

        $user_vs_institute = {
            map { $_->{id} => $_->{institute_id} } $self->schema->resultset('User')->search(
                {
                    ( 'me.id' => $params{user_id} ) x !!exists $params{user_id}, active => 1
                },
                {
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator'
                }
            )->all
        };

        $self->_merge_regions_values(
            sum               => $sum_values,
            inputed           => $inputed_values,
            institutes        => $institutes_conf,
            user_vs_institute => $user_vs_institute,
        );

        #use DDP; p "FINAL \$inputed_values" if $DEBUG;
        #use DDP; p $inputed_values if $DEBUG;

        #use DDP; p "FINAL \$sum_values" if $DEBUG;
        #use DDP; p $sum_values if $DEBUG;

        # associa pra variavel que ficou com tudo junto.
        $period_values = $inputed_values;

        # remove os valores inativos, pois estes nao farão parte de nenhum indicador.
        delete $inputed_values->{0};

        undef $sum_values;
    }
    else {
        $period_values = $self->_get_values_periods($values_rs);
    }

    my $variation_values = $self->_get_values_variation(
        indicators => \@indicators,

        # se nao foi informado a regiao, nao tem calculo dela.
        exists $params{regions_id}
        ? ( 'regions_id' => $params{regions_id} )
        : ( 'regions_id' => undef ),

        ( 'user_id' => $params{user_id} ) x !!exists $params{user_id},

        ( valid_from => $params{dates} ) x !!exists $params{dates},

        institutes        => $institutes_conf,
        user_vs_institute => $user_vs_institute,
    );

    # limpa alguma memoria
    undef $institutes_conf;
    undef $user_vs_institute;

    my ( $variation_var_per_ind ) =
      $self->_get_indicator_var_variables( indicators => \@indicators );

    my $results = $self->_get_indicator_values(
        indicators => \@indicators,
        values     => $period_values,

        indicator_variables => $indicator_variables,
        variation_values    => $variation_values,
        ind_variation_var   => $variation_var_per_ind

    );

    #use DDP;
    #p $results if $DEBUG;

    my $results_count = keys %$results;
    ##use DDP; p $indicator_variables; p $variation_values; p $results;
    my $users_meta =
      $results_count ? $self->get_users_meta( users => [ map { keys %{ $results->{$_} } } keys %$results ] ) : undef;

    my $regions_meta = $results_count ? $self->get_regions_meta( keys %$results ) : undef;

    $self->schema->txn_do(
        sub {
            my $indval_rs = $self->schema->resultset('IndicatorValue');

            my $where = {
                ( 'me.valid_from' => $params{dates} ) x !!exists $params{dates},
                ( 'me.user_id'      => $params{user_id} ) x !!exists $params{user_id},
                ( 'me.indicator_id' => $params{indicators} ) x !!exists $params{indicators},

               #( 'me.generated_by_compute' => $params{generated_by_compute} ) x !!exists $params{generated_by_compute},

                # se nao foi informado a regiao, nao tem calculo dela.
                exists $params{regions_id}
                ? ( 'me.region_id' => { 'in' => $params{regions_id} }, )
                : ( 'me.region_id' => undef ),

            };

            #   use DDP; p $where;
            $indval_rs->search($where)->delete;

            while ( my ( $region_id, $region_data ) = each %$results ) {
                undef $region_id if $region_id eq 'null';

                while ( my ( $user_id, $indicators ) = each %$region_data ) {

                    while ( my ( $indicator_id, $dates ) = each %$indicators ) {

                        while ( my ( $date, $variations ) = each %$dates ) {

                            while ( my ( $variation, $actives ) = each %$variations ) {

                                my $ins = {
                                    user_id      => $user_id,
                                    indicator_id => $indicator_id,
                                    valid_from   => $date,
                                    city_id      => defined $region_id
                                    ? $regions_meta->{$region_id}{city_id}
                                    : $users_meta->{$user_id}{city_id},

                                    institute_id   => $users_meta->{$user_id}{institute_id},
                                    variation_name => $variation,

                                    value       => $variations->{$variation}[0],
                                    sources     => $variations->{$variation}[1],
                                    values_used => $variations->{$variation}[2],

                                    region_id => $region_id,

                                };
                                $indval_rs->create($ins);

                            }
                        }
                    }
                }
            }

            if ( scalar @upper_regions ) {

                #print STDERR "-" x 100, "\n";
                #use DDP; p \@upper_regions if $DEBUG;
                $self->upsert(
                    %params,

                    regions_id => \@upper_regions,
                );
            }
        }
    );

}

# retorna cidade / institudo dos usuarios
sub get_users_meta {
    my ( $self, %params ) = @_;

    my $user_rs = $self->schema->resultset('User')->search( { 'me.id' => { in => $params{users} } } )->as_hashref;

    my $users = {};

    while ( my $row = $user_rs->next ) {
        $users->{ $row->{id} } = {
            city_id      => $row->{city_id},
            institute_id => $row->{institute_id}
        };
    }

    return $users;
}

# retorna cidade das regioes
sub get_regions_meta {
    my ( $self, @regions ) = @_;

    my $citys =
      $self->schema->resultset('Region')->search( { 'me.id' => { 'in' => [ grep { /\d/o } @regions ] } } )->as_hashref;

    my $regions = {};

    while ( my $row = $citys->next ) {
        $regions->{ $row->{id} } = { city_id => $row->{city_id}, };

        #push @$level3, $row->{id} if $row->{depth_level} == 3;
    }

    return $regions;
}

# faz o merge entre a soma das subregioes e o valor nao ativo da cidade
# inputed = valores da cidade.
# sum     = valores somados
sub _merge_regions_values {
    my ( $self, %conf ) = @_;

    # corre a soma, e transforma o inputed em 1 se nao existir.
    while ( my ( $region_id, $users ) = each %{ $conf{sum}{1} } ) {
        next if $region_id eq 'null';

        while ( my ( $user_id, $dates ) = each %{$users} ) {

            next unless $conf{institutes}{ $conf{user_vs_institute}{$user_id} };

            while ( my ( $date, $variables ) = each %{$dates} ) {

                while ( my ( $varid, $value ) = each %{$variables} ) {

                    # se ja tem valor ativo pro ano, ele fica.
                    next if exists $conf{inputed}{1}{$region_id}{$user_id}{$date}{$varid};

                    # fala que o inptuado eh a soma.
                    $conf{inputed}{1}{$region_id}{$user_id}{$date}{$varid} = $value;
                }

            }
        }
    }

    # percorre os inputados falsos, trasnforma em 1 e nao tem região.
    while ( my ( $region_id, $users ) = each %{ $conf{inputed}{0} } ) {
        next if $region_id eq 'null';

        while ( my ( $user_id, $dates ) = each %{$users} ) {

            next unless $conf{institutes}{ $conf{user_vs_institute}{$user_id} };

            while ( my ( $date, $variables ) = each %{$dates} ) {

                while ( my ( $varid, $value ) = each %{$variables} ) {

                    # se ja tem valor ativo pro ano, ele fica.
                    next if exists $conf{sum}{1}{$region_id}{$user_id}{$date}{$varid};

                    $conf{inputed}{1}{$region_id}{$user_id}{$date}{$varid} = $value;
                }

            }
        }
    }

}

# monta na RAM a estrutura:
# $period_values = $region_id => $user_id => { $valid_from => { $variable_id => [ $value, $source ] } }
# assim fica facil saber se em determinado periodo
# existem dados para todas as variaveis

sub _get_values_periods {
    my ( $self, $rs ) = @_;

    $rs = $rs->as_hashref;

    my $out = {};

    while ( my $row = $rs->next ) {

        next if !defined $row->{value} || $row->{value} eq '';

        $out->{'1'}{'null'}{ $row->{user_id} }{ $row->{valid_from} }{ $row->{variable_id} } =
          [ $row->{value}, $row->{source}, ];
    }

    return $out;
}

sub _get_values_periods_region {
    my ( $self, %params ) = @_;

    my $rs = $params{rs}->as_hashref;

    my $out = $params{out};

    while ( my $row = $rs->next ) {
        next if !defined $row->{value} || $row->{value} eq '';
        $out->{ $row->{active_value} }{ $row->{region_id} }{ $row->{user_id} }{ $row->{valid_from} }
          { $row->{variable_id} } = [ $row->{value}, $row->{source}, ];
    }

    return $out;
}

# monta na RAM a estrutura:
# {
#    $region: $user_id:  {
#       $variable_id =>  $variation_name: {
#            $value_period: $value
#        },
# }

sub _get_values_variation {
    my ( $self, %params ) = @_;

    my @indicator_ids;
    foreach my $indicator ( @{ $params{indicators} } ) {
        next unless $indicator->indicator_type eq 'varied';
        push @indicator_ids, $indicator->id;
    }
    return {} unless scalar @indicator_ids;

    my @conds = (
        ( indicator_id => { 'in' => \@indicator_ids } ),
        (
            'indicator_variables_variations_values.valid_from' => {
                'in' => $params{valid_from}
            }
          ) x !!exists $params{valid_from},

        (
            'indicator_variables_variations_values.user_id' => { 'in' => $params{user_id} }
          ) x !!exists $params{user_id},

        '-and' => [
            { 'indicator_variables_variations_values.value' => { '!=' => undef } },
            { 'indicator_variables_variations_values.value' => { '!=' => '' } }
        ]
    );

    # se tem região, ai é outro processo, amigo!
    if ( $params{regions_id} ) {

        # carrega separado os valores, assim como nos valores das regioes, só que agora
        # usando um hash, no lugar de duas variaveis...
        my $loads = {};
        for my $load_type ( ( undef, 1 ) ) {
            my $variations_rs = $self->schema->resultset('IndicatorVariation')->search(
                {
                    'indicator_variables_variations_values.generated_by_compute' => $load_type,
                    'indicator_variables_variations_values.region_id'            => { in => $params{regions_id} },
                    @conds,
                },
                { prefetch => 'indicator_variables_variations_values' }
            )->as_hashref;

            while ( my $row = $variations_rs->next ) {
                foreach my $val ( @{ $row->{indicator_variables_variations_values} } ) {
                    $loads->{
                        $load_type
                        ? 'sum'
                        : 'inputed'
                      }{ $val->{active_value} }
                      { $val->{region_id} }{ $val->{user_id} }{ $val->{indicator_variables_variation_id} }
                      { $row->{name} }{ $val->{valid_from} } = $val->{value};
                }
            }
        }

        #############

        # corre a soma, e transforma o inputed em 1 se nao existir.
        while ( my ( $region_id, $users ) = each %{ $loads->{sum}{1} } ) {
            next if $region_id eq 'null';

            while ( my ( $user_id, $var_variation_ids ) = each %{$users} ) {

                next unless $params{institutes}{ $params{user_vs_institute}{$user_id} };

                while ( my ( $var_variation_id, $variation_names ) = each %{$var_variation_ids} ) {

                    while ( my ( $variation_name, $valid_froms ) = each %{$variation_names} ) {

                        while ( my ( $date, $value ) = each %{$valid_froms} ) {

                            # se ja tem valor ativo pro ano, ele fica.
                            next
                              if exists $loads->{inputed}{1}{$region_id}{$user_id}{$var_variation_id}{$variation_name}
                              {$date};

                            # fala que o inptuado eh a soma.
                            $loads->{inputed}{1}{$region_id}{$user_id}{$var_variation_id}{$variation_name}{$date} =
                              $value;
                        }
                    }
                }
            }
        }

        # percorre os inputados falsos, trasnforma em 1 e nao tem região.
        while ( my ( $region_id, $users ) = each %{ $loads->{inputed}{0} } ) {
            next if $region_id eq 'null';

            while ( my ( $user_id, $var_variation_ids ) = each %{$users} ) {

                next unless $params{institutes}{ $params{user_vs_institute}{$user_id} };

                while ( my ( $var_variation_id, $variation_names ) = each %{$var_variation_ids} ) {

                    while ( my ( $variation_name, $valid_froms ) = each %{$variation_names} ) {

                        while ( my ( $date, $value ) = each %{$valid_froms} ) {

                            # se ja tem valor ativo pro ano, ele fica.
                            next
                              if
                              exists $loads->{sum}{1}{$region_id}{$user_id}{$var_variation_id}{$variation_name}{$date};

                            # fala que o inptuado eh a soma.
                            $loads->{inputed}{1}{$region_id}{$user_id}{$var_variation_id}{$variation_name}{$date} =
                              $value;
                        }
                    }
                }
            }
        }

        return $loads->{inputed};

        #############

    }
    else {
        # se nao tem regiao, otimo, e ja pode até mandar carregar apenas os valores ativos!

        my $variations_rs = $self->schema->resultset('IndicatorVariation')->search(
            {
                'indicator_variables_variations_values.active_value' => 1,
                'indicator_variables_variations_values.region_id'    => undef,
                @conds,
            },
            { prefetch => 'indicator_variables_variations_values' }
        )->as_hashref;

        my $out = {};
        while ( my $row = $variations_rs->next ) {
            foreach my $val ( @{ $row->{indicator_variables_variations_values} } ) {
                $out->{ $val->{active_value} }{'null'}{ $val->{user_id} }{ $val->{indicator_variables_variation_id} }
                  { $row->{name} }{ $val->{valid_from} } = $val->{value};
            }
        }

        return $out;
    }

    return die '?';
}

sub _get_indicator_var_variables {
    my ( $self, %params ) = @_;

    my @indicator_ids;
    foreach my $indicator ( @{ $params{indicators} } ) {
        next unless $indicator->indicator_type eq 'varied';
        push @indicator_ids, $indicator->id;
    }
    return {} unless scalar @indicator_ids;

    my $variables_rs =
      $self->schema->resultset('IndicatorVariablesVariation')
      ->search( { indicator_id => { 'in' => \@indicator_ids }, } )->as_hashref;

    my $out  = {};
    #my $out2 = {};
    while ( my $row = $variables_rs->next ) {
        $out->{ $row->{indicator_id} }{ $row->{id} } = $row->{name};
     #   $out2->{ $row->{id} } = 1;
    }

    return ( $out,  );
}

sub _get_indicator_values {
    my ( $self, %params ) = @_;

    my $out = {};
    foreach my $indicator ( @{ $params{indicators} } ) {

        my @variables =
          exists $params{indicator_variables}{ $indicator->id }
          ? sort { $a <=> $b } @{ $params{indicator_variables}{ $indicator->id } }
          : ();

        # todo esse IF serve para colocar as datas faltantes
        # nos indicadores que nao tem variaveis "normais"
        # ou entao eles nunca entrariam no loop
        # entao aqui procursa-se por todos as datas dos valores das variacoes
        if ( $indicator->indicator_type eq 'varied' ) {
            next unless ref $params{variation_values} eq 'HASH';

            while ( my ( $active_value, $regions ) = each %{ $params{variation_values} } ) {
                next unless ref $regions eq 'HASH';

                while ( my ( $region_id, $users ) = each %$regions ) {
                    next unless ref $users eq 'HASH';

                    foreach my $user_id ( keys %$users ) {
                        my $var_values = $params{variation_values}{$active_value}{$region_id}{$user_id};

                        foreach my $var_variable_id ( keys %{ $params{ind_variation_var}{ $indicator->id } } ) {

                            foreach my $variation ( keys %{ $var_values->{$var_variable_id} } ) {

                                foreach my $date ( keys %{ $var_values->{$var_variable_id}{$variation} } ) {

                                    if ( !exists $params{values}{$active_value}{$region_id}{$user_id}{$date} ) {
                                        $params{values}{$active_value}{$region_id}{$user_id}{$date} = {};
                                    }
                                }
                            }
                        }
                    }
                }

            }
        }

        # só eh consolidado os registros ativos.
        my $active_value = 1;

        foreach my $region_id ( keys %{ $params{values}{$active_value} } ) {

            foreach my $user_id ( keys %{ $params{values}{$active_value}{$region_id} } ) {

                # percorre todos os periodos desse usuario
                foreach my $date ( keys %{ $params{values}{$active_value}{$region_id}{$user_id} } ) {
                    my $data = $params{values}{$active_value}{$region_id}{$user_id}{$date};

                    # verifica se todas as variaveis estao preenchidas
                    my $filled = 0;
                    do { $filled++ if exists $data->{$_} }
                      for @variables;
                    next unless $filled == @variables;

                    my %sources;
                    for my $var (@variables) {
                        my $str = $data->{$var}[1];
                        next unless $str;
                        $sources{$str}++;
                    }
                    my $formula = Iota::IndicatorFormula->new(
                        formula    => $indicator->formula,
                        schema     => $self->schema,
                        auto_check => 0
                    );

                    my %values = map { $_ => $data->{$_}[0] } @variables;

                    if ( $indicator->indicator_type eq 'varied' ) {

                        my $var_variables = $params{ind_variation_var}{ $indicator->id };
                        my $var_values    = $params{variation_values}{$active_value}{$region_id}{$user_id};

                        my $filled_variations = {};
                        foreach my $var_variable_id ( keys %$var_variables ) {
                            foreach my $variation ( keys %{ $var_values->{$var_variable_id} } ) {
                                next unless exists $var_values->{$var_variable_id}{$variation}{$date};
                                $filled_variations->{$variation}++;
                            }
                        }

                        foreach my $variation ( keys %$filled_variations ) {

                            # pula as variaveis nao totalmente preenchidas em todas as variações
                            next unless $filled_variations->{$variation} == scalar keys %$var_variables;

                            my %varied_values =
                              map { $_ => $var_values->{$_}{$variation}{$date} } keys %$var_variables;

                            my @calcvars = (
                                V => \%values,
                                N => \%varied_values
                            );
                            my $valor = $formula->evaluate_with_alias(@calcvars);

                            $out->{$region_id}{$user_id}{ $indicator->id }{$date}{$variation} =
                              [ $valor, [ keys %sources ], encode_json( {@calcvars} ) ];
                        }

                    }
                    else {
                        my $valor = $formula->evaluate(%values);

                        # '' = variacao
                        $out->{$region_id}{$user_id}{ $indicator->id }{$date}{''} =
                          [ $valor, [ keys %sources ], encode_json( \%values ) ];
                    }

                }
            }
        }    # region

    }
    return $out;
}

sub indicators_from_variables {
    my ( $self, %params ) = @_;

    die "param variables missing" unless exists $params{variables};

    my @indicators = $self->schema->resultset('IndicatorVariable')->search(
        { variable_id => $params{variables} },
        {
            columns  => ['indicator_id'],
            group_by => ['indicator_id'],
        }
    )->all;

    my @ids = map { $_->indicator_id } @indicators;
    return wantarray ? @ids : \@ids;
}

sub indicators_from_variation_variables {
    my ( $self, %params ) = @_;

    die "param variables missing" unless exists $params{variables};

    my @indicators = $self->schema->resultset('IndicatorVariablesVariation')->search(
        { id => $params{variables} },
        {
            columns  => ['indicator_id'],
            group_by => ['indicator_id'],
        }
    )->all;

    my @ids = map { $_->indicator_id } @indicators;
    return wantarray ? @ids : \@ids;
}

1;
