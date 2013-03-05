package Iota::Controller::API::UserPublic::Indicator::Chart;

use Moose;



use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/userpublic/indicator/object') : PathPart('chart') : CaptureArgs(0) {}



sub typify : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $type ) = @_;

    my $controller = $c->controller('API::Indicator::Chart');
    $controller->typify($c, $type);

    $c->stash->{controller} = $controller;
}

sub render : Chained('typify') : PathPart('') : Args(0 ): ActionClass('REST') {}

=pod

GET /api/public/user/$id/indicator/12/chart/period_axis

Retorna a mesma coisa que o GET /api/indicator/$id/chart/period_axis?group_by=weekly&from=2002-02-01&to=2002-02-12


=cut

sub render_GET {
    my ( $self, $c ) = @_;

    $c->stash->{user_id} = $c->stash->{user_obj}->id;
    $c->stash->{controller}->render_GET( $c );
}





1;

