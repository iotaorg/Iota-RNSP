
package Iota::PCS::Controller::API::Indicator::Chart;

use Moose;
use JSON qw(encode_json);
use Iota::IndicatorChart;

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/indicator/object') : PathPart('chart') : CaptureArgs(0) {
  my ( $self, $c ) = @_;

  $c->stash->{indicator}  = $c->stash->{object}->next;
}

sub typify : Chained('base') : PathPart('') : CaptureArgs(1) {
  my ( $self, $c, $type ) = @_;
  $c->detach('/error_404') unless $type eq 'period_axis';


  $c->stash->{chart_type} = 'PeriodAxis';
}

sub render : Chained('typify') : PathPart('') : Args(0 ): ActionClass('REST') {
  my ( $self, $c ) = @_;

  $c->detach('/error_404'), $c->detach unless $c->stash->{indicator}->indicator_type eq 'normal';

}

=pod

=encoding utf-8

detalhe da variavel

GET /api/indicator/$id/chart/period_axis?group_by=weekly&from=2002-02-01&to=2002-02-12

retorna um objeto para montar graficos de
    X [time] / Y [value] com N series de valores

opcional:
    group_by one of: ('daily', 'weekly', 'monthly', 'bimonthly', 'quarterly', 'semi-annual', 'yearly', 'decade')
        desde que o periodo seja maior que o salvo no indicator
        default: indicator + 1 tempo (de dia, separa por semana, de semana por mes...)

    from: DateTime
    to: DateTime

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

sub render_GET {
  my ( $self, $c ) = @_;
  my $model = Iota::IndicatorChart->new_with_traits(
    traits => [$c->stash->{chart_type}],
    schema    => $c->model('DB'),
    indicator => $c->stash->{indicator_obj} || $c->stash->{indicator},
    user_id   => $c->stash->{user_id} || $c->user->id
  );

  my %options = (
    from     => $c->req->params->{from},
    to       => $c->req->params->{to},
    group_by => $c->req->params->{group_by},
  );
  my $ret = eval {$model->data( %options )};
  if ($@){
    $self->status_bad_request(
        $c,
        message => $@,
    );
  }else{
    $self->status_ok(
        $c,
        entity => $ret
    );
  }
}

1;

