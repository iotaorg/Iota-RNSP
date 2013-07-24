
package Iota::Controller::API::Public;

use Moose;
use Iota::IndicatorFormula;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/root') : PathPart('public') : CaptureArgs(0) {
}

sub network_object : Chained('/institute_load') : PathPart('api/public') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{collection} = $c->model('DB::User');
}

1;

