
package RNSP::PCS::Controller::API;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config( default => 'application/json' );

use Digest::SHA1 qw(sha1_hex);
use Time::HiRes qw(time);

sub api_key_check : Private {
    my ( $self, $c ) = @_;

    my $api_key = $c->req->param('api_key')
        || ( $c->req->data ? $c->req->data->{api_key} : undef );

    #    $self->status_forbidden( $c, message => "access denied", ), $c->detach
    #        unless defined $api_key
    #            && $c->user( $c->model('DB::User')->find( { api_key => $api_key } ) );
}

sub root : Chained('/') : PathPart('api') : CaptureArgs(0) {
}

sub login : Chained('root') : PathPart('login') : Args(0) : ActionClass('REST') {
}

sub login_POST {
    my ( $self, $c ) = @_;

    $self->status_bad_request( $c, message => 'Login invalid' ), $c->detach
        unless $c->model('DataManager')->success;

    if ( $c->authenticate( { map { $_ => $c->req->param( 'user.login.' . $_ ) } qw(email password) } ) ) {
        my %attrs = $c->user->get_inflated_columns;
        delete $attrs{password};
        $self->status_ok( $c, entity => \%attrs );
    }
    else {
        $self->status_bad_request( $c, message => 'Login invalid' );
    }

}

sub logout : Chained('base') : PathPart('logout') : Args(0) : ActionClass('REST') {
}

sub logout_GET {
    my ( $self, $c ) = @_;
    $c->logout;
    $self->status_ok( $c, entity => { logout => 'ok' } );
}

sub logged_in : Chained('root') : PathPart('') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->forward('api_key_check');
}

sub base : Chained('logged_in') : PathPart('') : CaptureArgs(0) {
}

1;

