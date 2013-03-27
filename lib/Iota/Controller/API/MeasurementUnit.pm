
package Iota::Controller::API::MeasurementUnit;

use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/base') : PathPart('measurement_unit') : CaptureArgs(0) {
  my ( $self, $c ) = @_;
  $c->stash->{collection} = $c->model('DB::MeasurementUnit');


}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
  my ( $self, $c, $id ) = @_;
  $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );


  $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub measurement_unit : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
  my ( $self, $c ) = @_;

}

=pod

=encoding utf-8

detalhe da cidade

GET /api/measurement_unit/$id

Retorna:

    {
        "id": "1",
        "created_at": "2012-09-27 18:55:53.480272",
        "name": "Foo Bar"
    }

=cut

sub measurement_unit_GET {
  my ( $self, $c ) = @_;
  my $object_ref  = $c->stash->{object}->as_hashref->next;

  $self->status_ok(
    $c,
    entity => {
      (map { $_ => $object_ref->{$_} } qw(name short_name id user_id created_at))
    }
  );
}

=pod

atualizar cidade

POST /api/measurement_unit/$id

Retorna:

    measurement_unit.update.name      Texto

=cut

sub measurement_unit_POST {
  my ( $self, $c ) = @_;

  $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->check_any_user_role(qw(admin superadmin));

  $c->req->params->{measurement_unit}{update}{id} = $c->stash->{object}->next->id;

  my $dm = $c->model('DataManager');

  $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
    unless $dm->success;

  my $obj = $dm->get_outcome_for('measurement_unit.update');

  $self->status_accepted(
    $c,
    location =>
      $c->uri_for( $self->action_for('measurement_unit'), [ $obj->id ] )->as_string,
        entity => { name => $obj->name, id => $obj->id }
    ),
    $c->detach
    if $obj;
}


=pod

apagar cidade

DELETE /api/measurement_unit/$id

Retorna: No-content ou Gone

=cut

sub measurement_unit_DELETE {
  my ( $self, $c ) = @_;

  $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->check_any_user_role(qw(admin superadmin));

  my $obj = $c->stash->{object}->next;
  $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

  $obj->delete;

  $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}


=pod

listar cidades

GET /api/measurement_unit

Retorna:

    {
        "measurement_units": [
            {
                "name": "Foo Bar",
            }
        ]
    }

=cut

sub list_GET {
  my ( $self, $c ) = @_;

    my @list = $c->stash->{collection}->as_hashref->all;
    my @objs;

    foreach my $obj (@list){
        push @objs, {
            (map { $_ => $obj->{$_} } qw(id name short_name)),
            url => $c->uri_for_action( $self->action_for('measurement_unit'), [ $obj->{id} ] )->as_string,
        }
    }

    $self->status_ok(
        $c,
        entity => {
        measurement_units => \@objs
        }
    );
}


=pod

criar cidade

POST /api/measurement_unit

Param:

    measurement_unit.create.name      Texto, Requerido: nome da cidade

Retorna:

    {"name":"Foo Bar","id":3}

=cut

sub list_POST {
  my ( $self, $c ) = @_;

  $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->check_any_user_role(qw(admin superadmin));

  $c->req->params->{measurement_unit}{create}{user_id} = $c->user->id;

  my $dm = $c->model('DataManager');

  $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
    unless $dm->success;
  my $object = $dm->get_outcome_for('measurement_unit.create');

  $self->status_created(
    $c,
    location => $c->uri_for( $self->action_for('measurement_unit'), [ $object->id ] )->as_string,
    entity => {
      name => $object->name,
      id   => $object->id,
    }
  );

}

with 'Iota::TraitFor::Controller::Search';
1;

