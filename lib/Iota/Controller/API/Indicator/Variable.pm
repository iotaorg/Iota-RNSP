
package Iota::Controller::API::Indicator::Variable;

use Moose;
use JSON qw(encode_json);
use Iota::IndicatorFormula;

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/indicator/object') : PathPart('variable') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{indicator} = $c->stash->{object}->next;
}

sub values : Chained('base') : PathPart('value') : Args(0 ) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

=pod

GET /api/indicator/<ID>/variable/value

retorna os valores das variaveis em forma de tabela
com variacao:
\ {
    filters:  {
        user_id:  [
            [0] 2,
            [1] 2
        ]
    },
    header :  {
        'Foo Bar0':  0
    },
    rows   :  [
        [0] {
            formula_value:  88,
            valid_from   :  "2010-01-01T00:00:00",
            valores      :  [
                [0] {
                    id           :  13783,
                    observations :  undef,
                    source       :  undef,
                    value        :  15,
                    value_of_date:  "2010-01-01T00:00:00",
                    variable_id  :  3784
                }
            ],
            variations   :  [
                [0] {
                    name :  "Até 1/2 salário mínimo.",
                    value:  19
                },
                [1] {
                    name :  "Mais de 1/2 a 1 salário mínimo.",
                    value:  21
                },
                [2] {
                    name :  "Mais de 1 a 2 salários mínimos.",
                    value:  22
                },
                [3] {
                    name :  "outros.",
                    value:  26
                }
            ]
        },
        [1] {
            formula_value:  82,
            valid_from   :  "2011-01-01T00:00:00",
            valores      :  [
                [0] {
                    id           :  13785,
                    observations :  undef,
                    source       :  undef,
                    value        :  16,
                    value_of_date:  "2011-01-01T00:00:00",
                    variable_id  :  3784
                }
            ],
            variations   :  [
                [0] {
                    name :  "Até 1/2 salário mínimo.",
                    value:  21
                },
                [1] {
                    name :  "Mais de 1/2 a 1 salário mínimo.",
                    value:  21
                },
                [2] {
                    name :  "Mais de 1 a 2 salários mínimos.",
                    value:  18
                },
                [3] {
                    name :  "outros.",
                    value:  22
                }
            ]
        },
        [2] {
            formula_value:  95,
            valid_from   :  "2012-01-01T00:00:00",
            valores      :  [
                [0] {
                    id           :  13787,
                    observations :  undef,
                    source       :  undef,
                    value        :  17,
                    value_of_date:  "2012-01-01T00:00:00",
                    variable_id  :  3784
                }
            ],
            variations   :  [
                [0] {
                    name :  "Até 1/2 salário mínimo.",
                    value:  23
                },
                [1] {
                    name :  "Mais de 1/2 a 1 salário mínimo.",
                    value:  22
                },
                [2] {
                    name :  "Mais de 1 a 2 salários mínimos.",
                    value:  24
                },
                [3] {
                    name :  "outros.",
                    value:  26
                }
            ]
        },
        [3] {
            formula_value:  100,
            valid_from   :  "2013-01-01T00:00:00",
            valores      :  [
                [0] {
                    id           :  13788,
                    observations :  undef,
                    source       :  undef,
                    value        :  18,
                    value_of_date:  "2013-01-01T00:00:00",
                    variable_id  :  3784
                }
            ],
            variations   :  [
                [0] {
                    name :  "Até 1/2 salário mínimo.",
                    value:  23
                },
                [1] {
                    name :  "Mais de 1/2 a 1 salário mínimo.",
                    value:  23
                },
                [2] {
                    name :  "Mais de 1 a 2 salários mínimos.",
                    value:  26
                },
                [3] {
                    name :  "outros.",
                    value:  28
                }
            ]
        }
    ]
}
sem variacao:
\ {
    header:  {
        nostradamus          :  1,
        'Temperatura semanal':  0
    },
    rows  :  [
        [0]  {
            formula_value:  22,
            valid_from   :  "1192-01-19T00:00:00",
            valores      :  [
                [0] {
                    id           :  13752,
                    observations :  undef,
                    source       :  undef,
                    value        :  21,
                    value_of_date:  "1192-01-21T00:00:00",
                    variable_id  :  3776
                },
                [1] {
                    id           :  13763,
                    observations :  undef,
                    source       :  undef,
                    value        :  1,
                    value_of_date:  "1192-01-21T00:00:00",
                    variable_id  :  3783
                }
            ]
        },
        [1]  {
            formula_value:  24,
            valid_from   :  "1192-02-09T00:00:00",
            valores      :  [
                [0] {
                    id           :  13753,
                    observations :  undef,
                    source       :  undef,
                    value        :  22,
                    value_of_date:  "1192-02-12T00:00:00",
                    variable_id  :  3776
                },
                [1] {
                    id           :  13764,
                    observations :  undef,
                    source       :  undef,
                    value        :  2,
                    value_of_date:  "1192-02-12T00:00:00",
                    variable_id  :  3783
                }
            ]
        },
        [2]  {
            formula_value:  30,
            valid_from   :  "1192-03-22T00:00:00",
            valores      :  [
                [0] {
                    id           :  13754,
                    observations :  undef,
                    source       :  undef,
                    value        :  25,
                    value_of_date:  "1192-03-25T00:00:00",
                    variable_id  :  3776
                },
                [1] {
                    id           :  13765,
                    observations :  undef,
                    source       :  undef,
                    value        :  5,
                    value_of_date:  "1192-03-25T00:00:00",
                    variable_id  :  3783
                }
            ]
        },
        [3]  {
            formula_value:  30,
            valid_from   :  "2011-01-16T00:00:00",
            valores      :  [
                [0] {
                    id           :  13748,
                    observations :  undef,
                    source       :  undef,
                    value        :  25,
                    value_of_date:  "2011-01-21T00:00:00",
                    variable_id  :  3776
                },
                [1] {
                    id           :  13759,
                    observations :  undef,
                    source       :  undef,
                    value        :  5,
                    value_of_date:  "2011-01-21T00:00:00",
                    variable_id  :  3783
                }
            ]
        },
        [4]  {
            formula_value:  34,
            valid_from   :  "2011-02-06T00:00:00",
            valores      :  [
                [0] {
                    id           :  13749,
                    observations :  undef,
                    source       :  undef,
                    value        :  27,
                    value_of_date:  "2011-02-12T00:00:00",
                    variable_id  :  3776
                },
                [1] {
                    id           :  13760,
                    observations :  undef,
                    source       :  undef,
                    value        :  7,
                    value_of_date:  "2011-02-12T00:00:00",
                    variable_id  :  3783
                }
            ]
        },
        [5]  {
            formula_value:  34,
            valid_from   :  "2011-03-20T00:00:00",
            valores      :  [
                [0] {
                    id           :  13750,
                    observations :  undef,
                    source       :  undef,
                    value        :  27,
                    value_of_date:  "2011-03-25T00:00:00",
                    variable_id  :  3776
                },
                [1] {
                    id           :  13761,
                    observations :  undef,
                    source       :  undef,
                    value        :  7,
                    value_of_date:  "2011-03-25T00:00:00",
                    variable_id  :  3783
                }
            ]
        },
        [6]  {
            formula_value:  38,
            valid_from   :  "2011-04-10T00:00:00",
            valores      :  [
                [0] {
                    id           :  13751,
                    observations :  undef,
                    source       :  undef,
                    value        :  29,
                    value_of_date:  "2011-04-16T00:00:00",
                    variable_id  :  3776
                },
                [1] {
                    id           :  13762,
                    observations :  undef,
                    source       :  undef,
                    value        :  9,
                    value_of_date:  "2011-04-16T00:00:00",
                    variable_id  :  3783
                }
            ]
        },
        [7]  {
            formula_value:  26,
            valid_from   :  "2012-01-01T00:00:00",
            valores      :  [
                [0] {
                    id           :  13744,
                    observations :  undef,
                    source       :  undef,
                    value        :  23,
                    value_of_date:  "2012-01-01T00:00:00",
                    variable_id  :  3776
                },
                [1] {
                    id           :  13755,
                    observations :  undef,
                    source       :  undef,
                    value        :  3,
                    value_of_date:  "2012-01-01T00:00:00",
                    variable_id  :  3783
                }
            ]
        },
        [8]  {
            formula_value:  30,
            valid_from   :  "2012-02-19T00:00:00",
            valores      :  [
                [0] {
                    id           :  13745,
                    observations :  undef,
                    source       :  undef,
                    value        :  25,
                    value_of_date:  "2012-02-22T00:00:00",
                    variable_id  :  3776
                },
                [1] {
                    id           :  13756,
                    observations :  undef,
                    source       :  undef,
                    value        :  5,
                    value_of_date:  "2012-02-22T00:00:00",
                    variable_id  :  3783
                }
            ]
        },
        [9]  {
            formula_value:  32,
            valid_from   :  "2012-03-04T00:00:00",
            valores      :  [
                [0] {
                    id           :  13746,
                    observations :  undef,
                    source       :  undef,
                    value        :  26,
                    value_of_date:  "2012-03-08T00:00:00",
                    variable_id  :  3776
                },
                [1] {
                    id           :  13757,
                    observations :  undef,
                    source       :  undef,
                    value        :  6,
                    value_of_date:  "2012-03-08T00:00:00",
                    variable_id  :  3783
                }
            ]
        },
        [10] {
            formula_value:  36,
            valid_from   :  "2012-04-08T00:00:00",
            valores      :  [
                [0] {
                    id           :  13747,
                    observations :  undef,
                    source       :  undef,
                    value        :  28,
                    value_of_date:  "2012-04-12T00:00:00",
                    variable_id  :  3776
                },
                [1] {
                    id           :  13758,
                    observations :  undef,
                    source       :  undef,
                    value        :  8,
                    value_of_date:  "2012-04-12T00:00:00",
                    variable_id  :  3783
                }
            ]
        }
    ]
}

=cut

sub values_GET {
    my ( $self, $c ) = @_;
    my $ret;
    my $hash = {};
    eval {
        my $indicator = $c->stash->{indicator_obj} || $c->stash->{indicator};

        my @indicator_variations;
        my @indicator_variables;
        if ( $indicator->indicator_type eq 'varied' ) {

            if ( $indicator->dynamic_variations ) {
                $hash->{filters} = { user_id => [ $indicator->user_id, $c->stash->{user_id} || $c->user->id ] };
                @indicator_variations =
                  $indicator->indicator_variations->search( $hash->{filters}, { order_by => 'order' } )->all;
            }
            else {
                $hash->{filters} = { user_id => $c->stash->{user_id} || $c->user->id };
                @indicator_variations = $indicator->indicator_variations->search( undef, { order_by => 'order' } )->all;
            }

            @indicator_variables = $indicator->indicator_variables_variations->all;

            foreach my $v (@indicator_variables) {
                push @{ $hash->{variables_variations} },
                  {
                    id   => $v->id,
                    name => $v->name,
                  };
            }
        }

        my $indicator_formula = Iota::IndicatorFormula->new(
            formula => $indicator->formula,
            schema  => $c->model('DB')->schema
        );
        my $valuetb      = $c->req->params->{region_id}           ? 'region_variable_values'        : 'values';
        my $active_value = exists $c->req->params->{active_value} ? $c->req->params->{active_value} : 1;

        my $cond = {
            -or => [
                $valuetb . '.user_id' => $c->stash->{user_id} || $c->user->id,
                $valuetb . '.user_id' => undef,
            ],
            'me.id' => [ $indicator_formula->variables ],

            (
                $valuetb eq 'region_variable_values'
                ? (
                    $valuetb . '.region_id'    => [ $c->req->params->{region_id}, undef ],
                    $valuetb . '.active_value' => $active_value
                  )
                : ()
            )
        };

        my $rs = $c->model('DB')->resultset('Variable')->search_rs( $cond, { prefetch => [$valuetb] } );

        my $tmp = {};
        my $x   = 0;
        while ( my $row = $rs->next ) {
            $hash->{header}{ $row->name } = $x;

            foreach my $value ( $row->$valuetb ) {
                push @{ $tmp->{ $value->valid_from } },
                  {
                    col           => $x,
                    varid         => $row->id,
                    value_of_date => $value->value_of_date->datetime,
                    value         => $value->value,
                    value_id      => $value->id,
                    observations  => $value->observations,
                    source        => $value->source,
                    name          => $row->name
                  };
            }
            $x++;
        }
        my $definidos = scalar keys %{ $hash->{header} };

        for my $variation (@indicator_variations) {

            my $rs = $variation->indicator_variables_variations_values->search(
                {
                    %{ $hash->{filters} },
                    region_id    => $c->req->params->{region_id},
                    active_value => $active_value
                },
                {
                    select   => [qw/valid_from/],
                    as       => [qw/valid_from/],
                    group_by => [qw/valid_from/]
                }
            );

            while ( my $item = $rs->next ) {
                push @{ $tmp->{ $item->valid_from } }, {};
            }
        }

        my $user_id = $c->stash->{user_id} || $c->user->id;

        foreach my $begin ( sort { $a cmp $b } keys %$tmp ) {

            my @order = sort { $a->{col} <=> $b->{col} } grep { exists $_->{col} } @{ $tmp->{$begin} };
            my $attrs = $c->model('DB')->resultset('UserIndicator')->search_rs(
                {
                    user_id      => $user_id,
                    valid_from   => $begin,
                    indicator_id => $indicator->id,
                    region_id    => $c->req->params->{region_id}
                }
            )->next;

            my $item = {
                formula_value => undef,
                valid_from    => $begin,
                valores       => []
            };
            foreach (@order) {
                $item->{valores}[ $hash->{header}{ $_->{name} } ] = {
                    variable_id   => $_->{varid},
                    value_of_date => $_->{value_of_date},
                    id            => $_->{value_id},
                    observations  => $_->{observations},
                    source        => $_->{source},
                    value         => $_->{value}
                };
            }

            @order = grep { defined $_->{value} } @order;

            if ($attrs) {
                $item->{justification_of_missing_field} = $attrs->justification_of_missing_field;
                $item->{goal}                           = $attrs->goal;
            }

            if ( $definidos == scalar @order ) {

                if ( @indicator_variables && @indicator_variations ) {

                    my $vals = {};

                    for my $variation (@indicator_variations) {

                        my $rs = $variation->indicator_variables_variations_values->search(
                            {
                                valid_from   => $begin,
                                user_id      => $user_id,
                                region_id    => $c->req->params->{region_id},
                                active_value => $active_value
                            }
                        )->as_hashref;
                        while ( my $r = $rs->next ) {
                            next unless defined $r->{value};
                            $vals->{ $r->{indicator_variation_id} }{ $r->{indicator_variables_variation_id} } =
                              $r->{value};
                        }

                        my $qtde_dados = keys %{ $vals->{ $variation->id } };

                        unless ( $qtde_dados == @indicator_variables ) {
                            $item->{variations}{ $variation->id } = { value => '-' };

                            delete $vals->{ $variation->id };
                        }
                    }

                    # TODO ler do indicador qual o totalization_method
                    my $sum = undef;
                    foreach my $variation_id ( keys %$vals ) {
                        $sum ||= 0;

                        my $val = $indicator_formula->evaluate_with_alias(
                            V => { map { $_->{varid} => $_->{value} } @order },
                            N => $vals->{$variation_id},
                        );

                        $item->{variations}{$variation_id} = { value => $val, orig => $vals->{$variation_id} };
                        $sum += $val;
                    }
                    $item->{formula_value} = $sum;

                    my @variations;

                    # corre na ordem
                    foreach my $var (@indicator_variations) {
                        push @variations,
                          {
                            name     => $var->name,
                            value    => $item->{variations}{ $var->id }{value},
                            original => $item->{variations}{ $var->id }{orig},
                          };
                    }
                    $item->{variations} = \@variations;

                }
                else {

                    if ( $indicator->formula =~ /#\d/ ) {
                        $item->{formula_value} = 'ERR#';
                    }
                    else {

                        $item->{formula_value} =
                          $indicator_formula->evaluate( map { $_->{varid} => $_->{value} } @order );
                    }
                }

            }

            push @{ $hash->{rows} }, $item;

        }

        $ret = $hash;
    };
    if ($@) {
        $self->status_bad_request( $c, message => "$@", );
    }
    else {
        $self->status_ok( $c, entity => $ret );
    }
}

sub period : Chained('base') : PathPart('period') : CaptureArgs( 1 ) {
    my ( $self, $c, $date ) = @_;
    $self->status_bad_request( $c, message => encode_json( { 'invalid.date' => 1 } ) ), $c->detach
      unless $date =~ /^\d{4}-\d{2}-\d{2}$/;

    $c->stash->{valid_from} = $date;
}

sub by_period : Chained('period') : PathPart('') : Args( 0 ) : ActionClass('REST') { }

=pod



GET /api/indicator/<ID>/variable/period/2010-01-01

retorna as variaveis de um indicador para um determinado periodo

{
    "valid_from": "2012-01-01",
    "rows": [
        {
            "source": null,
            "is_basic": 0,
            "value": "23",
            "name": "Temperatura semanal",
            "explanation": "a foo with bar",
            "value_id": 304,
            "cognomen": "temp_semana",
            "value_of_date": "2012-01-05T00:00:00",
            "type": "int",
            "id": 216
        },
        {
            "source": null,
            "is_basic": 0,
            "value": "3",
            "name": "nostradamus",
            "explanation": "nostradamus end of world",
            "value_id": 305,
            "cognomen": "nostradamus",
            "value_of_date": "2012-01-04T00:00:00",
            "type": "int",
            "id": "217"
        },
        {
            "source": null,
            "is_basic": 0,
            "value": null,
            "name": "XXXX",
            "explanation": "a foo with bar",
            "value_id": null,
            "cognomen": "XXXAA",
            "value_of_date": null,
            "id": "215",
            "type": "int"
        }
    ]
}

=cut

sub by_period_GET {
    my ( $self, $c ) = @_;
    my $ret;
    eval {
        my $indicator = $c->stash->{indicator_obj} || $c->stash->{indicator};

        my $indicator_formula = Iota::IndicatorFormula->new(
            formula => $indicator->formula,
            schema  => $c->model('DB')->schema
        );

        my $rs =
          $c->model('DB')->resultset('Variable')
          ->search_rs( { 'me.id' => [ $indicator_formula->variables ], }, { prefetch => ['measurement_unit'] } );

        my @rows;

        my $region_id = exists $c->req->params->{region_id} ? $c->req->params->{region_id} : undef;
        while ( my $row = $rs->next ) {
            my $rowx = {
                ( map { $_ => $row->$_ } qw /id name explanation cognomen type source is_basic/ ),

                value         => undef,
                value_of_date => undef,
                value_id      => undef,
                observations  => undef,
                source        => undef,

                # measurement_unit continua aqui apenas para manter retrocompatibilidade
                measurement_unit      => $row->measurement_unit ? $row->measurement_unit->short_name : undef,
                measurement_unit_name => $row->measurement_unit ? $row->measurement_unit->name       : undef,

            };
            my $value_table = $region_id ? 'region_variable_values' : 'values';
            my $active_value = exists $c->req->params->{active_value} ? $c->req->params->{active_value} : 1;

            my $rsx = $row->$value_table->search(
                {
                    'me.valid_from' => $c->stash->{valid_from},
                    'me.user_id'    => $c->stash->{user_id} || $c->user->id,
                    ( 'me.region_id'    => $region_id,
                      'me.active_value' => $active_value
                    ) x !!$region_id
                }
            );
            my $value = $rsx->first;
            if ($value) {
                $rowx = {
                    %{$rowx},
                    value         => $value->value,
                    value_of_date => $value->value_of_date->datetime,
                    value_id      => $value->id,
                    observations  => $value->observations,
                    source        => $value->source
                };
            }
            push @rows, $rowx;
        }
        $ret = { rows => \@rows, valid_from => $c->stash->{valid_from} };

        my $attrs = $c->model('DB')->resultset('UserIndicator')->search_rs(
            {
                user_id => $c->stash->{user_id} || $c->user->id,
                valid_from   => $c->stash->{valid_from},
                indicator_id => $indicator->id,
                region_id    => $region_id
            }
        )->next;

        if ($attrs) {
            $ret->{justification_of_missing_field} = $attrs->justification_of_missing_field;
            $ret->{goal}                           = $attrs->goal;
            $ret->{user_indicator_id}              = $attrs->id;
        }
        $ret->{action} = $attrs ? 'update' : 'create';

    };

    if ($@) {
        $self->status_bad_request( $c, message => "$@", );
    }
    else {
        $self->status_ok( $c, entity => $ret );
    }
}

1;

