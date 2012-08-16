package RNSP::PCS::Controller::API::User::ForgotPassword;

use namespace::autoclean;
use JSON qw(encode_json);
use Moose;

use utf8;

BEGIN { extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/root') : PathPart('user/forgot_password') :
  CaptureArgs(0) {
  my ( $self, $c ) = @_;

  #$c->stash->{collection} =
  #  $c->stash->{organization}->related_resultset('users');
}

sub email : Chained('base') : PathPart('email') : Args(0) : ActionClass('REST')
{
  my ( $self, $c ) = @_;
}

sub email_POST {
  my ( $self, $c ) = @_;

  my $dm = $c->model('DataManager');

  $self->status_bad_request( $c, message => 'verifique o parametro de email' ),
    $c->detach
    unless $dm->success;

  my $outcome = eval { $dm->get_outcome_for('user.forgot_password') };

  if ($@) {
    $self->status_bad_request( $c, message => 'ocorreu um erro no servidor.' ),
      $c->detach;
  }
  elsif ($outcome) {
    $self->status_ok( $c, entity => { message => 'ok' } );
  }

}

sub reset_password : Chained('base') : PathPart('reset_password') : Args(0) :
  ActionClass('REST') {
}

sub reset_password_POST {
  my ( $self, $c ) = @_;

  my $dm  = $c->model('DataManager');
  my $err = $dm->errors;

  $self->status_bad_request( $c, message => 'Chave expirada' ),
    $c->logx(
    'sys',
    "Tentativa de trocar de senha com chave expirada para e-mail "
      . $c->req->param('user.reset_password.email') . "."
    ),
    $c->detach
    if $err->{'user.reset_password.secret_key.invalid'};

  $self->status_bad_request( $c, message => 'Senha não confere' ), $c->detach
    if $err->{'user.reset_password.password.invalid'};

  $self->status_bad_request( $c, message => 'Confira os dados enviados.' ),
    $c->detach
    unless $dm->success;

  my $user = $dm->get_outcome_for('user.reset_password');


  $self->status_ok( $c, entity => { message => 'ok' } );
}

1;

