
package RNSP::PCS::Controller::API::Variable::Value;

use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/variable/object') : PathPart('value') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{collection} = $c->model('DB::VariableValue');
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
  my ( $self, $c, $id ) = @_;
  $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
  $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub variable : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
  my ( $self, $c ) = @_;

}

=pod

=encoding utf-8

detalhe do valor da variavel

GET /api/variable/$id/value/$id

Retorna:

    {
        "created_at": "2012-08-20 05:41:54.427052",
        "value": "123",
        "cognomen": "foobar",
        "name": "Foo Bar",
        "type": "int",

        "created_by": {
            "name": "admin",
            "id": 1
        },
        "value_of_date": "2012-08-20 05:41:54.427052",
        source
        observations

    }

=cut

sub variable_GET {
  my ( $self, $c ) = @_;
  my $object_ref  = $c->stash->{object}->search(undef, {prefetch => ['owner','variable']})->as_hashref->next;

  $self->status_ok(
    $c,
    entity => {
      created_by => {
        map { $_ => $object_ref->{owner}{$_} } qw(name id)
      },
      (map { $_ => $object_ref->{variable}{$_} } qw(name type cognomen)),
      (map { $_ => $object_ref->{$_} } qw(value created_at value_of_date observations source))
    }
  );
}

=pod

atualizar variavel

POST /api/variable/$id/value/$id

Retorna:

    variable.value.update.value     Texto: valor


=cut

sub variable_POST {
  my ( $self, $c ) = @_;

  $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->check_any_user_role(qw(admin user));

  my $obj_rs = $c->stash->{object}->next;
  # removido: $c->user->id != $obj_rs->owner->id
  if (!$c->check_any_user_role(qw(admin user))){
    $self->status_forbidden( $c, message => "access denied", ), $c->detach;
  }
  $c->req->params->{variable}{value}{update}{id} = $obj_rs->id;


  my $dm = $c->model('DataManager');

  $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
    unless $dm->success;

  my $obj = $dm->get_outcome_for('variable.value.update');

  $self->status_accepted(
    $c,
    location =>
      $c->uri_for( $self->action_for('variable'), [ $c->stash->{variable}->id,$obj->id ] )->as_string,
        entity => { id => $obj->id }
    ),
    $c->detach
    if $obj;
}


=pod

remove o valor para a variavel para o usuario logado

DELETE /api/variable/$id/value/$id

Retorna: No-content ou Gone

=cut

sub variable_DELETE {
  my ( $self, $c ) = @_;

  $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->check_any_user_role(qw(admin user));

  my $obj = $c->stash->{object}->next;
  $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

  if ($c->user->id == $obj->owner->id || $c->check_any_user_role(qw(admin))){
    $obj->delete;
  }

  $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}


=pod

define o valor para a variavel para o usuario logado

POST /api/variable/$id/value

Param:

    variable.value.create.value        Texto, Requerido: valor

Retorna:

    {"id":3}

=cut

sub list_POST {
  my ( $self, $c ) = @_;

  $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->check_any_user_role(qw(admin user));

  $c->req->params->{variable}{value}{create}{variable_id} = $c->stash->{variable}->id;

  $c->req->params->{variable}{value}{create}{user_id} = $c->user->id;

  my $dm = $c->model('DataManager');

  $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
    unless $dm->success;

  my $object = $dm->get_outcome_for('variable.value.create');

  $self->status_created(
    $c,
    location => $c->uri_for( $self->action_for('variable'), [ $c->stash->{variable}->id, $object->id ] )->as_string,
    entity => {
      id   => $object->id
    }
  );

}

=pod

cria ou atualiza o valor para a variavel para o usuario logado em determinado periodo.


PUT /api/variable/$id/value

Param:

    variable.value.put.value         Texto, Requerido: valor
    variable.value.put.value_of_date Data , Requerido: data

Retorna:

    {"id":3, "valid_from":"2012-01-01", "valid_until":"2012-01-02" }

=cut

sub list_PUT {
  my ( $self, $c ) = @_;

  $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->check_any_user_role(qw(admin user));

  $c->req->params->{variable}{value}{put}{variable_id} = $c->stash->{variable}->id;
  $c->req->params->{variable}{value}{put}{user_id} = $c->user->id;

  my $dm = $c->model('DataManager');

  $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
    unless $dm->success;

  my $object = $dm->get_outcome_for('variable.value.put');
  # retorna created, mas pode ser updated
  $self->status_created(
    $c,
    location => $c->uri_for( $self->action_for('variable'), [ $c->stash->{variable}->id, $object->id ] )->as_string,
    entity => {
      id            => $object->id,
      valid_from    => $object->valid_from->ymd,
      valid_until   => $object->valid_until->ymd
    }
  );

}


1;

