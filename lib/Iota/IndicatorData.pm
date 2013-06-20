package Iota::IndicatorData;

use Moose;
use Iota::IndicatorFormula;
has schema => (
    is       => 'ro',
    isa      => 'Any',
    required => 1
);

sub upsert {
    my ( $self, %params ) = @_;
    my $ind_rs = $self->schema->resultset('Indicator');

    # procura pelos indicadores enviados
    $ind_rs = $ind_rs->search( { id => $params{indicators} } )
      if exists $params{indicators};

    my @indicators = $ind_rs->all;
    my @indicators_ids = map { $_->id } @indicators;
    return unless scalar @indicators;

    # procura por todas as variaveis que esses indicadores podem utilizar
    my @used_variables =
      $self->schema->resultset('IndicatorVariable')->search( { indicator_id => \@indicators_ids } )->all;

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

    if ( exists $params{regions_id} ) {

        # procura pelos valores salvos naquela regiao
        my $rr_values_rs = $self->schema->resultset('RegionVariableValue');
        $rr_values_rs = $rr_values_rs->search( { valid_from => $params{dates} } ) if exists $params{dates};

        $rr_values_rs = $rr_values_rs->search(
            {
                ( 'me.user_id' => $params{user_id} ) x !!exists $params{user_id},
                'me.variable_id' => { 'in' => [ keys %$variable_ids ] },
                'me.region_id'   => { 'in' => $params{regions_id} }
            }
        );

        $self->_get_values_periods_region(
            out => $period_values,
            rs  => $rr_values_rs
        );
    }
    else {
        $period_values = $self->_get_values_periods($values_rs);
    }

    my $variation_values = $self->_get_values_variation(
        indicators => \@indicators,

        # se nao foi informado a regiao, nao tem calculo dela.
        exists $params{regions_id}
        ? ( 'region_id' => $params{regions_id} )
        : ( 'region_id' => undef ),
    );
    my $ind_variation_var = $self->_get_indicator_var_variables( indicators => \@indicators );

    my $results = $self->_get_indicator_values(
        indicators => \@indicators,
        values     => $period_values,

        indicator_variables => $indicator_variables,
        variation_values    => $variation_values,
        ind_variation_var   => $ind_variation_var

    );
    my $users_meta = $self->get_users_meta( users => [ map { keys %{ $results->{$_} } } keys %$results ] );
    my $regions_meta = $self->get_regions_meta( keys %$results );

    $self->schema->txn_do(
        sub {
            my $indval_rs = $self->schema->resultset('IndicatorValue');

            $indval_rs->search(
                {
                    ( 'me.valid_from' => $params{dates} ) x !!exists $params{dates},
                    ( 'me.user_id'      => $params{user_id} ) x !!exists $params{user_id},
                    ( 'me.indicator_id' => $params{indicators} ) x !!exists $params{indicators},

                    # se nao foi informado a regiao, nao tem calculo dela.
                    exists $params{regions_id}
                    ? ( 'me.region_id' => $params{regions_id} )
                    : ( 'me.region_id' => undef ),
                }
            )->delete;

            while ( my ( $region_id, $region_data ) = each %$results ) {
                undef $region_id if $region_id eq 'null';

                while ( my ( $user_id, $indicators ) = each %$region_data ) {

                    while ( my ( $indicator_id, $dates ) = each %$indicators ) {

                        while ( my ( $date, $variations ) = each %$dates ) {

                            foreach my $variation ( keys %$variations ) {

                                $indval_rs->create(
                                    {
                                        user_id      => $user_id,
                                        indicator_id => $indicator_id,
                                        valid_from   => $date,
                                        city_id      => defined $region_id
                                        ? $regions_meta->{$region_id}{city_id}
                                        : $users_meta->{$user_id}{city_id},
                                        institute_id   => $users_meta->{$user_id}{institute_id},
                                        variation_name => $variation,

                                        value   => $variations->{$variation}[0],
                                        sources => $variations->{$variation}[1],

                                        region_id => $region_id
                                    }
                                );

                            }
                        }
                    }
                }
            }

        }
    );

}

# retorna cidade / institudo dos usuarios
sub get_users_meta {
    my ( $self, %params ) = @_;

    my $user_rs =
      $self->schema->resultset('User')->search( { 'me.id' => $params{users} } )->as_hashref;

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

    my $users = {};

    while ( my $row = $citys->next ) {
        $users->{ $row->{id} } = { city_id => $row->{city_id}, };
    }

    return $users;
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

        $out->{'null'}{ $row->{user_id} }{ $row->{valid_from} }{ $row->{variable_id} } =
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
        $out->{ $row->{region_id} }{ $row->{user_id} }{ $row->{valid_from} }{ $row->{variable_id} } =
          [ $row->{value}, $row->{source}, ];
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

    my $variations_rs = $self->schema->resultset('IndicatorVariation')->search(
        {
            indicator_id                                      => \@indicator_ids,
            'indicator_variables_variations_values.region_id' => $params{region_id}
        },
        { prefetch => 'indicator_variables_variations_values' }
    )->as_hashref;

    my $out = {};
    while ( my $row = $variations_rs->next ) {

        foreach my $val ( @{ $row->{indicator_variables_variations_values} } ) {
            next if !defined $val->{value} || $val->{value} eq '';

            my $region_id = $val->{region_id} || 'null';
            $out->{$region_id}{ $val->{user_id} }{ $val->{indicator_variables_variation_id} }{ $row->{name} }
              { $val->{valid_from} } = $val->{value};

        }
    }

    return $out;
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
      $self->schema->resultset('IndicatorVariablesVariation')->search( { indicator_id => \@indicator_ids, } )
      ->as_hashref;

    my $out = {};
    while ( my $row = $variables_rs->next ) {
        $out->{ $row->{indicator_id} }{ $row->{id} } = $row->{name};
    }
    return $out;
}

sub _get_indicator_values {
    my ( $self, %params ) = @_;

    my $out = {};
    foreach my $indicator ( @{ $params{indicators} } ) {

        my @variables =
          exists $params{indicator_variables}{ $indicator->id }
          ? sort { $a <=> $b } @{ $params{indicator_variables}{ $indicator->id } }
          : ();

        foreach my $region_id ( keys %{ $params{values} } ) {

            foreach my $user_id ( keys %{ $params{values}{$region_id} } ) {

                # todo esse IF serve para colocar as datas faltantes
                # nos indicadores que nao tem variaveis "normais"
                # entao eles nunca entrariam no loop
                # entao aqui procursa-se por todos as datas dos valores das variacoes
                if ( $indicator->indicator_type eq 'varied' ) {
                    my $var_values = $params{variation_values}{$region_id}{$user_id};

                    foreach my $var_variable_id ( keys %{ $params{ind_variation_var}{ $indicator->id } } ) {

                        foreach my $variation ( keys %{ $var_values->{$var_variable_id} } ) {

                            foreach my $date ( keys %{ $var_values->{$var_variable_id}{$variation} } ) {

                                $params{values}{$region_id}{$user_id}{$date} = {}
                                  if !exists $params{values}{$region_id}{$user_id}{$date};
                            }
                        }
                    }
                }

                # percorre todos os periodos desse usuario
                foreach my $date ( keys %{ $params{values}{$region_id}{$user_id} } ) {
                    my $data = $params{values}{$region_id}{$user_id}{$date};

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
                        formula => $indicator->formula,
                        schema  => $self->schema
                    );

                    my %values = map { $_ => $data->{$_}[0] } @variables;

                    if ( $indicator->indicator_type eq 'varied' ) {

                        my $var_variables = $params{ind_variation_var}{ $indicator->id };
                        my $var_values    = $params{variation_values}{$region_id}{$user_id};

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

                            my %varied_values = map { $_ => $var_values->{$_}{$variation}{$date} } keys %$var_variables;

                            my $valor = $formula->evaluate_with_alias(
                                V => \%values,
                                N => \%varied_values
                            );
                            $out->{$region_id}{$user_id}{ $indicator->id }{$date}{$variation} =
                              [ $valor, [ keys %sources ] ];
                        }

                    }
                    else {
                        my $valor = $formula->evaluate(%values);

                        # '' = variacao
                        $out->{$region_id}{$user_id}{ $indicator->id }{$date}{''} = [ $valor, [ keys %sources ] ];
                    }

                }
            }
        }

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
