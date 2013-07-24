package Iota::Controller::API::Public::Indicator::Chart;

use Moose;

use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/public/indicator/object') : PathPart('chart') : CaptureArgs(0) { }

sub typify : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $type ) = @_;

    my $controller = $c->controller('API::Indicator::Chart');
    $controller->typify( $c, $type );

    $c->stash->{controller} = $controller;
}

sub render : Chained('typify') : PathPart('') : Args(0 ) : ActionClass('REST') { }

=pod

GET /api/public/indicator/12/chart/period_axis

=cut

sub render_GET {
    my ( $self, $c ) = @_;

    $c->stash->{user_id} = $c->stash->{network_data}{users_ids};
    $c->stash->{controller}->render_GET($c);
}

1;

