package Iota::Controller::API::User::Indicator;

use Moose;
use JSON qw (encode_json);
BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/user/object') : PathPart('indicator') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{user} = $c->stash->{object}->next;
    $c->stash->{collection} = $c->stash->{user}->user_indicators;

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
  my ( $self, $c, $id ) = @_;
  $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
  $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub indicator : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
  my ( $self, $c ) = @_;

}

=pod

=encoding utf-8

informacoes sobre um preenchimento especifico de um indicador sobre um periodo.

GET /api/user/$id/indicator/$id

Retorna:

{
    goal                          :  "bass down low",
    indicator_id                  :  35,
    justification_of_missing_field:  undef,
    valid_from                    :  "2012-11-18"
}


=cut

sub indicator_GET {
  my ( $self, $c ) = @_;
  my $object_ref  = $c->stash->{object}->as_hashref->next;

  $self->status_ok(
    $c,
    entity => {
      (map { $_ => $object_ref->{$_} } qw(goal valid_from justification_of_missing_field  indicator_id))
    }
  );
}

=pod

atualizar variavel

POST /api/user/$id/indicator/$id

Retorna:

    user.indicator.update.justification_of_missing_field
    user.indicator.update.goal

=cut

sub indicator_POST {
  my ( $self, $c ) = @_;

  $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->check_any_user_role(qw(admin user));

  my $obj_rs = $c->stash->{object}->next;

  if ( $c->user->id != $obj_rs->user_id || !$c->check_any_user_role(qw(admin))){
    $self->status_forbidden( $c, message => "access denied", ), $c->detach;
  }

    my $param = $c->req->params->{user}{indicator}{update};
  $param->{id} = $obj_rs->id;


  my $dm = $c->model('DataManager');

  $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
    unless $dm->success;

  my $obj = $dm->get_outcome_for('user.indicator.update');

  $c->logx('Adicionou informação no indicador na data ' . $obj->valid_from,
        indicator_id => $param->{indicator_id}
    );

  $self->status_accepted(
    $c,
        location => $c->uri_for( $self->action_for('indicator'), [ $c->stash->{user}->id, $obj->id ] )->as_string,
        entity => { id => $obj->id }
    ),

    $c->detach;
}


=pod

Apaga o registro da tabela UserIndicator

DELETE /api/user/$id/indicator/$id

Retorna: No-content ou Gone

=cut

sub indicator_DELETE {
  my ( $self, $c ) = @_;

  $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->check_any_user_role(qw(admin user));

  my $obj = $c->stash->{object}->next;
  $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

  if ($c->user->id == $obj->user_id || $c->check_any_user_role(qw(admin))){
    $c->logx('Apagou informação de indicador ' . $obj->id);
    $obj->delete;
  }


  $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}


=pod

define o valor para a variavel para o usuario logado

POST /api/user/$id/indicator

Param:

    user.indicator.create.justification_of_missing_field
    user.indicator.create.goal
    user.indicator.create.indicator_id
    user.indicator.create.valid_from

    -- valid_from: data que esta salvando o valor..
    -- pode passar a mesma data que ta usando pra preencher qualquer
    -- um dos valores das variaveis
    -- que eu vou buscar a primeira variavel do indicador pra usar como periodo

Retorna:

    {"id":3}

=cut

sub list_POST {
  my ( $self, $c ) = @_;

  $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->check_any_user_role(qw(admin user));

    my $param = $c->req->params->{user}{indicator}{create};
    $param->{user_id} = $c->stash->{user}->id;

  my $dm = $c->model('DataManager');

  $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
    unless $dm->success;

  my $object = $dm->get_outcome_for('user.indicator.create');

    $c->logx('Adicionou informação no indicador na data ' . $object->valid_from,
        indicator_id => $param->{indicator_id}
    );
  $self->status_created(
    $c,
    location => $c->uri_for( $self->action_for('indicator'), [ $c->stash->{user}->id, $object->id ] )->as_string,
    entity => {
      id   => $object->id
    }
  );

}



1;

