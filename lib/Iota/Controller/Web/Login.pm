package Iota::Controller::Web::Login;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
use utf8;
use JSON::XS;

sub logout : Chained('/') PathPart('logout') Args(0) {
    my ( $self, $c ) = @_;

    $c->logout;

    $c->detach( '/web/form/redirect_ok', [ '/index', [], {}, '' ] );
}

sub base : Chained('/institute_load') PathPart('login') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        custom_wrapper => 'site/iota_wrapper',
        v2             => 1,
    );

    $c->forward('/load_status_msgs');
}

sub index : Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{title} = 'Login: ' . $c->stash->{network}->name;

    $c->stash->{networks} = [
        $c->model('DB::Network')->search(
            {
                is_virtual => 0
            },
            {
                columns      => ['domain_name'],
                result_class => 'DBIx::Class::ResultClass::HashRefInflator'
            }
        )->all
    ];

}

sub do_account : Chained('base') PathPart('new-account') Args(0) {
    my ( $self, $c ) = @_;

    my $dm = $c->model('DataManager');

    unless ( $dm->success ) {
        $c->stash->{error}      = 'Confira os campos inválidos.';
        $c->stash->{form_error} = $dm->errors;

        $c->detach( '/web/form/redirect_error', [] );
    }

    my $object = eval { $dm->get_outcome_for('end_user.create') };

    if ($object) {

        my $user     = $c->req->params->{'end_user.create.email'};
        my $password = $c->req->params->{'end_user.create.password'};

        $c->authenticate( { email => $user, password => $password }, 'enduser' );

        $c->detach( '/web/form/redirect_ok', [ '/index', [], {}, 'Conta criada com sucesso! Navegue no site e siga os indicadores!' ] );
    }

    $c->log->error("$@") if $@;

    $c->stash->{error} = 'Erro desconhecido.';
    $c->detach( '/web/form/redirect_error', [] );

}

sub check : Chained('base') PathPart('check') Args(0) {
    my ( $self, $c ) = @_;

    if (    my $user = $c->req->params->{email}
        and my $password = $c->req->params->{password} ) {
        if (
            $c->authenticate(
                {
                    email    => $user,
                    password => $password
                },
                'enduser'
            )
          ) {

            $c->detach( '/web/form/redirect_ok', [ '/index', [], {}, 'Bem vindo, ' . $c->user->name ] );

        }
        else {
            $c->stash->{error} = 'Usuário ou senha inválidos.';
            $c->detach( '/web/form/redirect_error', [] );
        }
    }
    else {
        $c->stash->{error} = 'Usuário ou senha inválidos.';
        $c->detach( '/web/form/redirect_error', [] );
    }

}

__PACKAGE__->meta->make_immutable;

1;
