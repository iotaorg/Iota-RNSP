
package RNSP::PCS::Controller::API::Period;
use utf8;
use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/root') : PathPart('period') : CaptureArgs(0) {
  my ( $self, $c ) = @_;

}


sub year_base: Chained('base') : PathPart('year') : CaptureArgs(0) {

}

sub year_obj: Chained('year_base') : PathPart('') : CaptureArgs(1) {
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


=pod

retorna os anos possiveis

GET /api/period/year

{
    "options": [
        {
            "text": "2000",
            "value": "2000-01-01"
        },
        {
            "text": "2001",
            "value": "2001-01-01"
        },...
    ]
}

=cut

sub year : Chained('year_base') : PathPart('') : Args(0) : ActionClass('REST') {
}

sub year_GET {
  my ( $self, $c ) = @_;

    my $today = DateTime->now()->year() - 1;

    $self->status_ok(
        $c,
        entity => {
            options => [ map { +{
                value => $_ . '-01-01',
                text => "$_"
            }  } (2000 .. $today)]
        }
    );
}



=pod

retorna os meses possiveis daquele ano

GET /api/period/year/2012/month

{
    "options": [
        {
            "text": "2000 Janeiro",
            "value": "2000-01-01"
        },
        {
            "text": "2000 Fevereiro",
            "value": "2000-02-01"
        },...
    ]
}

=cut

sub month : Chained('year_obj') : PathPart('month') : Args(0) : ActionClass('REST') {
}

sub month_GET {
  my ( $self, $c ) = @_;

    my $max = 12;
    my $year = $c->stash->{year};
    $max = DateTime->now()->month() - 1 if (DateTime->now()->year() == $year);

    if ($max == 0){
        $year--;
        $max = 12;
    }
    my @meses = qw /
        Janeiro
        Fevereiro
        Março
        Abril
        Maio
        Junho
        Julho
        Agosto
        Setembro
        Outubro
        Novembro
        Dezembro
    /;
    $self->status_ok(
        $c,
        entity => {
            options => [ map { +{
                value => $year . '-' . sprintf('%02s', $_) . '-01',
                text => "$year - " . $meses[$_-1]
            }  } (1 .. $max)]
        }
    );
}



1;

