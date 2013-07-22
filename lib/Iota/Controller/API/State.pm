
package Iota::Controller::API::State;

use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/base') : PathPart('state') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{collection} = $c->model('DB::State');

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
        $self->status_bad_request( $c, message => 'invalid.argument' ), $c->detach
      unless $id =~ /^[0-9]+$/;

    $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );

    $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub state : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

=pod

=encoding utf-8

detalhe da cidade

GET /api/state/$id

Retorna:

    {
        "id": "1",
        "created_at": "2012-09-27 18:55:53.480272",
        "name": "Foo Bar"
    }

=cut

sub state_GET {
    my ( $self, $c ) = @_;
    my $object_ref = $c->stash->{object}->as_hashref->next;

    $self->status_ok( $c,
        entity => { ( map { $_ => $object_ref->{$_} } qw(id name name_url uf country_id created_at created_by) ) } );
}

=pod

atualizar cidade

POST /api/state/$id

Retorna:

    state.update.name      Texto

=cut

sub state_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));

    $c->req->params->{state}{update}{id} = $c->stash->{object}->next->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $obj = $dm->get_outcome_for('state.update');

    $self->status_accepted(
        $c,
        location => $c->uri_for( $self->action_for('state'), [ $obj->id ] )->as_string,
        entity => { name => $obj->name, id => $obj->id }
      ),
      $c->detach
      if $obj;
}

=pod

apagar cidade

DELETE /api/state/$id

Retorna: No-content ou Gone

=cut

sub state_DELETE {
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

GET /api/state

Retorna:

    {
        "states": [
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

    foreach my $obj (@list) {
        push @objs,
          {
            ( map { $_ => $obj->{$_} } qw(id name name_url uf country_id created_at created_by) ),
            url => $c->uri_for_action( $self->action_for('state'), [ $obj->{id} ] )->as_string,
          };
    }

    $self->status_ok( $c, entity => { states => \@objs } );
}

=pod

criar cidade

POST /api/state

Param:

    state.create.name      Texto, Requerido: nome da cidade

Retorna:

    {"name":"Foo Bar","id":3}

=cut

sub list_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));

    $c->req->params->{state}{create}{created_by} = $c->user->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;
    my $object = $dm->get_outcome_for('state.create');

    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('state'), [ $object->id ] )->as_string,
        entity => {
            name     => $object->name,
            name_url => $object->name_url,
            id       => $object->id,
        }
    );

}

with 'Iota::TraitFor::Controller::Search';
1;

