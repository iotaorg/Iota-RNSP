package Iota::Controller::Web::Account;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
use utf8;
use JSON::XS;

sub base : Chained('/institute_load') PathPart('me') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->forward('/web/form/not_found') unless $c->user;

    $c->stash(
        custom_wrapper => 'site/iota_wrapper',
        v2             => 1,
    );

    $c->forward('/load_status_msgs');
}

sub index: Chained('base') PathPart('account') Args(0) {
    my ( $self, $c ) = @_;

    $c->req->params->{opt} = 'my-account' unless $c->req->params->{opt};

    $c->stash->{submenu} = [
        {
            name  => 'my-account',
            title => $c->loc('Minha conta'),
            init  => sub {
                $c->stash->{title} = $c->loc('Minha conta');
            }
        },
        {
            name  => 'indicators',
            title => $c->loc('Acompanhar indicadores'),
            init  => sub {

                $c->stash->{title} = $c->loc('Acompanhar indicadores');

                $c->forward( '/build_indicators_menu', [1] );

            }
        },
    ];

    foreach ( @{ $c->stash->{submenu} } ) {
        $c->stash->{submenu_ref}{ $_->{name} } = $_;
    }

    my $item = $c->stash->{submenu_ref}{ $c->req->params->{opt} };
    $c->forward('/web/form/not_found') unless $item;

    $item->{init}->();

    $item->{active} = 1;

    $c->stash->{active_submenu} = $item;
}


__PACKAGE__->meta->make_immutable;

1;
