package Iota::Controller::Web::Form;
use Moose;
use URI;
use URI::QueryParam;
use JSON;
use utf8;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub root : Chained('/') : PathPart('form') : CaptureArgs(0) {
}

sub redirect_ok : Private {
    my ( $self, $c, $path, $cap, $params, $msg, %args ) = @_;

    my $a = $c->uri_for_action(
        $path, $cap,
        {
            ( ref $params eq 'HASH' ? %$params : () ),
            mid => $c->set_status_msg(
                {
                    %args, status_msg => $msg
                }
            )
        }
    );
    die "uri not found" unless $a;

    $c->res->redirect($a);

}

sub as_json : Private {
    my ( $self, $c, $data ) = @_;

    $c->res->header( 'Content-type', 'application/json; charset=utf-8' );

    $c->res->body( encode_json($data) );

}

sub not_found : Private {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'not_found.tt';
    $c->detach();
}

sub redirect_error : Private {
    my ( $self, $c, %args ) = @_;

    my $host  = $c->req->uri->host;
    my $refer = $c->req->headers->referer;

    if ( !$refer || $refer !~ /^https?:\/\/$host/i ) {
        $refer = '/erro';
    }

    # opa, o cara nao ta logado, VAI PRA HOME!
    # se tirar, redirect-loop acontece!

    $refer = '/erro'
      if !$c->user && $refer !~ /(login)(\?|$)/;

    my $mid = $c->set_error_msg(
        {
            form_error => $c->stash->{form_error},
            body       => $c->req->params,
            error_msg  => $c->stash->{error},
        }
    );

    my $uri = URI->new($refer);
    $uri->query_param( 'mid', $mid );

    $c->res->redirect( $uri->as_string );

}

__PACKAGE__->meta->make_immutable;

1;
