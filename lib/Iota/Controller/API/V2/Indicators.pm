package Iota::Controller::API::V2::Indicators;
use Moose;
use Iota::IndicatorFormula;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/institute_load') : PathPart('indicators') : CaptureArgs(0) {
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub list_GET {
    my ( $self, $c ) = @_;

    $c->forward( 'API::UserPublic' => 'stash_indicators_and_users' );
    $c->stash->{rest} = { indicators => $c->stash->{rest}{indicators} };
}

1;

