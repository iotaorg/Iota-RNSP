package Iota::Controller::Web::Account;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
use utf8;
use JSON::XS;

sub base : Chained('/institute_load') PathPart('me') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->forward('/web/form/need_login') unless $c->user;

    $c->stash(
        custom_wrapper  => 'site/iota_wrapper',
        v2              => 1,
        my_account_menu => 1,
    );

    $c->forward('/load_status_msgs');
}

sub index : Chained('base') PathPart('account') Args(0) {
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

                $c->stash->{web_open_axis} = 1;
                $c->forward( '/build_indicators_menu', [1] );

                $c->forward('load_end_user_indicators');

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

sub load_end_user_indicators : Private {
    my ( $self, $c ) = @_;

    my $following = {};

    my $rs = $c->user->end_user_indicators->search(
        {
            network_id => $c->stash->{network}->id
        },
        {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            columns      => [ 'id', 'indicator_id' ]
        }
    );

    while ( my $r = $rs->next ) {
        $following->{ $r->{indicator_id} } = $r;
    }
    $c->stash->{following} = $following;

}

sub end_user_indicator_modal_base : Chained('base') PathPart('end-user-indicator-modal') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->forward('/web/form/not_found') unless $id =~ /^[0-9]+$/;

    $c->stash->{end_user_indicator} = $c->user->end_user_indicators->search(
        {
            'me.id' => $id
        },
        {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            join         => [ 'end_user_indicator_users', 'indicator' ],
            collapse     => 1,
            columns      => [
                qw/
                  me.id
                  me.indicator_id
                  me.all_users
                  me.network_id

                  indicator.id
                  indicator.name

                  end_user_indicator_users.id
                  end_user_indicator_users.end_user_indicator_id
                  end_user_indicator_users.indicator_id
                  end_user_indicator_users.user_id

                  /
            ],
        }
      )->next
      or $c->forward('/web/form/not_found');

}

sub end_user_indicator_modal : Chained('end_user_indicator_modal_base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{without_wrapper} = 1;

}
__PACKAGE__->meta->make_immutable;

1;
