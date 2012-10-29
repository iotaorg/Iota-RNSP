package RNSP::PCS::Controller::API::UserPublic::Indicator::Variable;

use Moose;



use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/userpublic/indicator/object') : PathPart('variable') : CaptureArgs(0) {}




sub values :Chained('base') : PathPart('value') : Args( 0 ) : ActionClass('REST') {}


=pod

GET /api/public/user/$id/indicator/12/variable

Retorna a mesma coisa que o GET /api/indicator/<ID>/variable/value porem com o user_id passado na url

=cut

sub values_GET {
    my ( $self, $c ) = @_;

    $c->stash->{user_id} = $c->stash->{user_obj}->id;

    my $controller = $c->controller('API::Indicator::Variable');
    $controller->values_GET( $c );
}

1;

