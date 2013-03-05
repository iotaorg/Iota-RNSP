package Iota::Controller::API::UserPublic::Variable;

use Moose;

use  Iota::IndicatorFormula;
use Iota::IndicatorChart::PeriodAxis;

use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/userpublic/base') : PathPart('variable') : CaptureArgs(0) {
  my ( $self, $c, $id ) = @_;
  $c->stash->{collection} = $c->model('DB::Variable');
}


sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
  my ( $self, $c ) = @_;

}

sub list_GET {
    my ( $self, $c ) = @_;

    my $controller = $c->controller('API::Variable');
    $controller->list_GET( $c );
    if (ref $c->stash->{rest}{variables} eq 'ARRAY'){
        foreach (@{$c->stash->{rest}{variables}}){
            delete $_->{url}; # essa url é a private
        }
    }
}


1;

