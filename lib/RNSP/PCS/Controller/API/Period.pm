
package RNSP::PCS::Controller::API::Period;

use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/root') : PathPart('period') : CaptureArgs(0) {
  my ( $self, $c ) = @_;

}


sub year_obj: Chained('base') : PathPart('year') : CaptureArgs(1) {
  my ( $self, $c, $year ) = @_;

  $self->status_forbidden( $c, message => "access denied", ), $c->detach unless $year =~ /^[0-9]{4}$/;

  $c->stash->{year} = $year;
}


=pod

retorna os valores que devem entrar no checkbox para preencher as datas de um determinado ano

GET /api/period/year/2012/week

Retorna:
{
    "options": [
        {
            "text": "Semana 1 / 2012-01-01",
            "value": "2012-01-01"
        },
        {
            "text": "Semana 2 / 2012-01-08",
            "value": "2012-01-08"
        },...
    ]
}
=cut

sub week : Chained('year_obj') : PathPart('week') : Args(0) : ActionClass('REST') {
}

sub week_GET {
  my ( $self, $c ) = @_;

    my $list = $c->model('DB')->schema->get_weeks_of_year($c->stash->{year});

    $self->status_ok(
        $c,
        entity => {
            options => [ map { +{
                value => $_->{period_begin},
                text => $_->{period_begin} . " - Semana $_->{week_num}"
            }  } @$list]
        }
    );
}



1;

