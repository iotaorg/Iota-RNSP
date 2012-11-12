package RNSP::IndicatorChart::PeriodAxis;
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
        default: indicator + 1 tempo (de dia, separa por semana, de semana por mes...)

    from: str to DateTime
    to: str to DateTime

exemplo:

{
    "label": "Temperatura maxima do mes: SP",
    "axis": "Gestão Local para a Sustentabilidade",
    "goal": 32,
    "goal_operator": "<=",
    "series": [
        {
            "label": "Year 2011",
            "start": "2011-01-01",
            "avg": 24.8,
            "data": [
                ['2011-01-03', 18],
                ['2011-02-02', 22],
                ['2011-03-04', 33],
                ['2011-04-06', 25],
                ['2011-05-09', 26],
            ]
        },
        {
            "label": "Year 2012",
            "start": "2012-01-01",
            "avg": 25,
            "data": [
                ['2012-01-02', 23],
                ['2012-02-22', 21],
                ['2012-03-05', 31],
                ['2012-04-04', 23],
                ['2012-05-08', 27],
            ]
        }
    ]
}

=cut

sub read_values {
    my ($self, %options) = @_;

    my $group_by = $options{group_by} ? $self->_valid_or_null($options{group_by}) : 'yearly';
    my $indicator = $self->indicator;

    my $series = $self->_load_variables_values(%options, group_by => $group_by);
    my $data = {
        label            => $indicator->name,
        axis             => {
            name => $indicator->axis->name, id => $indicator->axis_id
        },
        goal             => $indicator->goal,
        goal_operator    => $indicator->goal_operator,
        goal_explanation => $indicator->goal_explanation,
        goal_source      => $indicator->goal_source,
        series           => []
    };

    foreach my $start (sort {$a cmp $b} keys %{$series}){
        my @data = ();
        my $row       = {
            start  => $start,
            data   => \@data
        };
        my $total = 0;
        foreach my $dt (sort {$a cmp $b} keys %{$series->{$start}{sets}}) {
            my $xy = $series->{$start}{sets}{$dt};  # Y
            $total = $total + $xy->[1];
            push @data, $xy;
        }
        $row->{avg}   = @data ?  $total / scalar @data : 0;
        $row->{label} = &get_label_of_period($start, $group_by);

        push @{$data->{series}}, $row;
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

        my $set = $values->{$gp}{sets}{$row->valid_from} = [
                $row->value_of_date->datetime, # X
                $row->value # Y
            ];
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
    }else{
        return $data;
    }
}


sub _valid_or_null {
    my ($self, $period) =  @_;
    return $period =~ /(daily|weekly|monthly|bimonthly|quarterly|semi-annual|yearly|decade)/ ? $1 : undef;
}


1;
