package Iota::IndicatorChart::PeriodAxis;
use Moose::Role;
use utf8;
use DateTime;
use DateTime::Format::Pg;

=pod

retorna um objeto para montar graficos de
    X [time] / Y [value] com N series de valores

opcional:
    group_by one of: ('daily', 'weekly', 'monthly', 'bimonthly', 'quarterly', 'semi-annual', 'yearly', 'decade')
        desde que o periodo seja maior que o salvo no indicator
        default: eh o mesmo do indicador

    from: str to DateTime
    to: str to DateTime

exemplo com os dados:

    &add_value($variable_url, '2012-02-01', 23);
    &add_value($variable_url, '2012-03-22', 25);
    &add_value($variable_url, '2012-04-08', 26);
    &add_value($variable_url, '2012-05-12', 28);


    &add_value($variable_url, '2011-02-21', 25);
    &add_value($variable_url, '2011-03-12', 27);
    &add_value($variable_url, '2011-04-25', 27);
    &add_value($variable_url, '2011-05-16', 29);

    &add_value($variable_url, '1192-02-21', 21);
    &add_value($variable_url, '1192-03-12', 22);
    &add_value($variable_url, '1192-04-25', 25);

    $variable_url = $uri2->path_query;

    &add_value($variable_url, '2012-02-01', 3);
    &add_value($variable_url, '2012-03-22', 5);
    &add_value($variable_url, '2012-04-08', 6);
    &add_value($variable_url, '2012-05-12', 8);


    &add_value($variable_url, '2011-02-21', 5);
    &add_value($variable_url, '2011-03-12', 7);
    &add_value($variable_url, '2011-04-25', 7);
    &add_value($variable_url, '2011-05-16', 9);

    &add_value($variable_url, '1192-02-21', 1);
    &add_value($variable_url, '1192-03-12', 2);
    &add_value($variable_url, '1192-04-25', 5);

    formula = var1 + var2

exemplo agrupado por ano:
\ {
    avg             :  30.5454545454545,
    axis            :  {
        id  :  2,
        name:  "Bens Naturais Comuns"
    },
    goal            :  33,
    goal_explanation:  undef,
    goal_operator   :  "<=",
    goal_source     :  "@fulano",
    group_by        :  "yearly",
    label           :  "Temperatura maxima do mes: SP",
    max             :  136,
    min             :  76,
    period          :  "weekly",
    series          :  [
        [0] {
            avg  :  25.3333333333333,
            data :  [
                [0] [
                    [0] "1192-02-16T00:00:00",
                    [1] 22
                ],
                [1] [
                    [0] "1192-03-08T00:00:00",
                    [1] 24
                ],
                [2] [
                    [0] "1192-04-19T00:00:00",
                    [1] 30
                ]
            ],
            label:  1192,
            max  :  30,
            min  :  22,
            start:  "1192-01-01",
            sum  :  76
        },
        [1] {
            avg  :  34,
            data :  [
                [0] [
                    [0] "2011-02-20T00:00:00",
                    [1] 30
                ],
                [1] [
                    [0] "2011-03-06T00:00:00",
                    [1] 34
                ],
                [2] [
                    [0] "2011-04-24T00:00:00",
                    [1] 34
                ],
                [3] [
                    [0] "2011-05-15T00:00:00",
                    [1] 38
                ]
            ],
            label:  2011,
            max  :  38,
            min  :  30,
            start:  "2011-01-01",
            sum  :  136
        },
        [2] {
            avg  :  31,
            data :  [
                [0] [
                    [0] "2012-01-29T00:00:00",
                    [1] 26
                ],
                [1] [
                    [0] "2012-03-18T00:00:00",
                    [1] 30
                ],
                [2] [
                    [0] "2012-04-08T00:00:00",
                    [1] 32
                ],
                [3] [
                    [0] "2012-05-06T00:00:00",
                    [1] 36
                ]
            ],
            label:  2012,
            max  :  36,
            min  :  26,
            start:  "2012-01-01",
            sum  :  124
        }
    ]
}



exemplo agrupado por decada:
\ {
    avg             :  30.5454545454545,
    axis            :  {
        id  :  2,
        name:  "Bens Naturais Comuns"
    },
    goal            :  33,
    goal_explanation:  undef,
    goal_operator   :  "<=",
    goal_source     :  "@fulano",
    group_by        :  "decade",
    label           :  "Temperatura maxima do mes: SP",
    max             :  260,
    min             :  76,
    period          :  "weekly",
    series          :  [
        [0] {
            avg  :  25.3333333333333,
            data :  [
                [0] [
                    [0] "1192-02-16T00:00:00",
                    [1] 22
                ],
                [1] [
                    [0] "1192-03-08T00:00:00",
                    [1] 24
                ],
                [2] [
                    [0] "1192-04-19T00:00:00",
                    [1] 30
                ]
            ],
            label:  "1190-1200",
            max  :  30,
            min  :  22,
            start:  "1190-01-01",
            sum  :  76
        },
        [1] {
            avg  :  32.5,
            data :  [
                [0] [
                    [0] "2011-02-20T00:00:00",
                    [1] 30
                ],
                [1] [
                    [0] "2011-03-06T00:00:00",
                    [1] 34
                ],
                [2] [
                    [0] "2011-04-24T00:00:00",
                    [1] 34
                ],
                [3] [
                    [0] "2011-05-15T00:00:00",
                    [1] 38
                ],
                [4] [
                    [0] "2012-01-29T00:00:00",
                    [1] 26
                ],
                [5] [
                    [0] "2012-03-18T00:00:00",
                    [1] 30
                ],
                [6] [
                    [0] "2012-04-08T00:00:00",
                    [1] 32
                ],
                [7] [
                    [0] "2012-05-06T00:00:00",
                    [1] 36
                ]
            ],
            label:  "2010-2020",
            max  :  38,
            min  :  26,
            start:  "2010-01-01",
            sum  :  260
        }
    ]
}


=cut

sub read_values {
    my ($self, %options) = @_;

    my $period;

    do{
        my ($anyid) = @{$self->variables};
        my $anyvar = $self->schema->resultset('Variable')->find($anyid);
        # return {error => 'novar'} unless $anyvar;

        $period = $anyvar ? $anyvar->period : 'yearly';

    };
    # NOTE 2013-02-05
    # tirei o default de $period pois o JS só funciona com ano
    my $group_by = $options{group_by} ? $self->_valid_or_null($options{group_by}) : 'yearly';

    my $indicator = $self->indicator;

    my $series    = $self->_load_variables_values(%options, group_by => $group_by);
    my @indicator_variations;
    my @indicator_variables;
    if ($indicator->indicator_type eq 'varied'){

        if ($indicator->dynamic_variations) {
            @indicator_variations = $indicator->indicator_variations->search({
                user_id => [$self->user_id, $indicator->user_id],
            }, {order_by=>'order'})->all;
        }else{
            @indicator_variations = $indicator->indicator_variations->search(undef, {order_by=>'order'})->all;
        }

        @indicator_variables  = $indicator->indicator_variables_variations->all;
    }
    my $data = {
        label            => $indicator->name,
        axis             => {
            name => $indicator->axis->name, id => $indicator->axis_id
        },
        goal             => $indicator->goal,
        goal_operator    => $indicator->goal_operator,
        goal_explanation => $indicator->goal_explanation,
        goal_source      => $indicator->goal_source,
        series           => [],
        period           => $period,
        group_by         => $group_by,

        min =>  9999999999999999,
        max => -9999999999999999
    };

    my $qtde = scalar @{$self->variables};
    my $total = 0;
    my $total_ok = 0;
    my $totali = 0;
    foreach my $start (sort {$a cmp $b} keys %{$series}){
        my @data = ();
        my $row       = {
            begin  => $start,
            sum    => 0,
            data   => \@data,
            min =>  9999999999999999,
            max => -9999999999999999
        };
        my $sum = 0;
        my $sum_ok = 0;
        my $total2 = 0;
        foreach my $dt (sort {$a cmp $b} keys %{$series->{$start}{sets}}) {
            my $vals_user = $series->{$start}{sets}{$dt};
            my $valor;

            # numero de variaveis preenchidas ok
            if ($qtde == keys %$vals_user){

                if (@indicator_variables && @indicator_variations){

                  my $vals = {};

                  for my $variation (@indicator_variations){

                     my $rs = $variation->indicator_variables_variations_values->search({
                        valid_from => $dt
                     })->as_hashref;
                     while (my $r = $rs->next){
                        next unless defined $r->{value};
                        $vals->{$r->{indicator_variation_id}}{$r->{indicator_variables_variation_id}} = $r->{value}
                     }

                     my $qtde_dados = keys %{$vals->{$variation->id}};

                     unless ($qtde_dados == @indicator_variables){
                        $row->{variations}{$variation->id} = {
                           value => '-'
                        };

                        delete $vals->{$variation->id};
                     }
                  }

                  # TODO ler do indicador qual o totalization_method
                  my $sum = 0;
                  foreach my $variation_id (keys %$vals){

                     my $val = $self->indicator_formula->evaluate_with_alias(
                        V => $vals_user,
                        N => $vals->{$variation_id},
                     );

                     $row->{variations}{$variation_id} = {
                        value => $val
                     };
                     $sum += $val;
                  }
                  $row->{formula_value} = $valor = $sum;

                  my @variations;
                  # corre na ordem
                  foreach my $var (@indicator_variations){
                     push @variations, {
                        name  => $var->name,
                        value => $row->{variations}{$var->id}{value}
                     };
                  }
                  $row->{variations} = \@variations;

               }else{

                  if ($indicator->formula =~ /#\d/ ){
                     $valor = 'ERR#';
                  }else{
                    $valor = $self->indicator_formula->evaluate( %$vals_user );
                  }
               }


            }else{
                $valor = '-';
            }

            if ($valor ne '-'){
                $sum_ok = $total_ok = 1;
                $total  += $valor;
                $sum    += $valor;
                $row->{max} = $valor if $valor > $row->{max};
                $row->{min} = $valor if $valor < $row->{min};
            }
            push @data, [$dt, $valor];



            $total2++;
            $totali++;
        }
        if ($total2 && $sum_ok){
            $row->{sum} = $sum;
            $row->{avg} = $total2 ? $sum / $total2 : $total2;

            $data->{max} = $sum if $sum > $data->{max};
            $data->{min} = $sum if $sum < $data->{min};
        }else{
            $row->{avg} = '-';
            $row->{sum} = '-';
            $row->{max} = '-';
            $row->{min} = '-';
        }

        $row->{label} = &get_label_of_period($start, $group_by);

        push @{$data->{series}}, $row;
    }
    if ($total_ok){
        $data->{avg} = $totali ? $total / $totali : '-';
    }else{
        $data->{avg} = '-';
    }


    $self->_data($data);
}

sub _load_variables_values {
    my ($self, %options) =  @_;

    my $rs = $self->schema->resultset('VariableValue')->search({
        variable_id => $self->variables,
        user_id     => $self->user_id,

        ( $options{from} ? (valid_from  => {'>=' => DateTime::Format::Pg->parse_datetime( $options{from} )->datetime }) : () ),
        ( $options{to}   ? (valid_until => {'<' => DateTime::Format::Pg->parse_datetime( $options{to}   )->datetime }) : () ),

    }, {
        '+select' => [ \['(SELECT x.period_begin FROM f_extract_period_edge(?, me.valid_from) x)', [ plain_value => $options{group_by} ]] ],
        '+as'     => ['group_from']
    } );

    my $values = {};

    while( my $row = $rs->next ){
        my $gp = $row->get_column('group_from') || 'all';
        next if $row->value eq '';
        $values->{$gp}{sets}{$row->valid_from}{$row->variable_id} = $row->value;
    }
    return $values;
}

sub get_label_of_period {
    my ($data, $period) =  @_;

    my $dt = DateTime::Format::Pg->parse_datetime( $data );

    if ($period eq 'weekly'){
        return 'semana ' . $dt->week;
    }elsif ($period eq 'monthly'){
        return $dt->month . ' de ' . $dt->year ;
    }elsif ($period eq 'bimonthly'){
        return $dt->month . ' e ' . ($dt->month + 1).' de ' . $dt->year ;
    }elsif ($period eq 'quarterly'){
        return $dt->quarter . ' trimeste de ' . $dt->year;
    }elsif ($period eq 'semi-annual'){
        return ($dt->month <= 6? '1 semestre' : '2 semestre') . ' de '. $dt->year;
    }elsif ($period eq 'yearly'){
        return $dt->year;
    }elsif ($period eq 'decade'){
        return $dt->year . '-'.($dt->year+10);
    }else{
        return $data;
    }
}


sub _valid_or_null {
    my ($self, $period) =  @_;
    return $period =~ /(daily|weekly|monthly|bimonthly|quarterly|semi-annual|yearly|decade)/ ? $1 : undef;
}


1;
