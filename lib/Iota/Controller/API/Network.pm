
package Iota::Controller::API::Network;

use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/base') : PathPart('network') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{collection} = $c->model('DB::Network');

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $self->status_bad_request( $c, message => 'invalid.argument' ), $c->detach
      unless $id =~ /^[0-9]+$/;

    $c->stash->{object} =
      $c->stash->{collection}->search_rs( { 'me.id' => $id } );

    $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub user : Chained('object') : PathPart('user') : Args(1) : ActionClass('REST')
{
    my ( $self, $c, $id ) = @_;
    $c->stash->{user_id} = $id;
}

sub user_POST {
    my ( $self, $c ) = @_;

    #    $self->status_forbidden( $c, message => "access denied", ), $c->detach
    #      unless $c->check_any_user_role(qw(superadmin));

    $c->stash->{network} = $c->stash->{object}->next;

    $c->stash->{network}
      ->add_to_network_users( { user_id => $c->stash->{user_id} } );

    #$self->status_bad_request( $c, message => encode_json( $dm->errors ) ),
    #  $c->detach
    #  unless $dm->success;

    #my $obj = $dm->get_outcome_for('network.update');

    $self->status_accepted(
        $c,
        location => $c->uri_for( $self->action_for('network'),
            [ $c->stash->{object}->{id} ] )->as_string,
        entity => { name => 'teste' }
      ),
      $c->detach;
}

sub network : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

=pod

=encoding utf-8

detalhe da cidade

GET /api/network/$id

Retorna:

    {
        "id": "1",
        "created_at": "2012-09-27 18:55:53.480272",
        "name": "Foo Bar"
    }

=cut

sub network_GET {
    my ( $self, $c ) = @_;
    my $object_ref = $c->stash->{object}->as_hashref->next;

    $self->status_ok(
        $c,
        entity => {
            (
                map { $_ => $object_ref->{$_} }
                  qw(
                  id name name_url created_at created_by

                  institute_id domain_name
                  )
            )
        }
    );
}

=pod

atualizar cidade

POST /api/network/$id

Retorna:

    network.update.name      Texto

=cut

sub network_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(superadmin));

    $c->req->params->{network}{update}{id} = $c->stash->{object}->next->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ),
      $c->detach
      unless $dm->success;

    my $obj = $dm->get_outcome_for('network.update');

    $self->status_accepted(
        $c,
        location =>
          $c->uri_for( $self->action_for('network'), [ $obj->id ] )->as_string,
        entity => { name => $obj->name, id => $obj->id }
      ),
      $c->detach
      if $obj;
}

=pod

apagar cidade

DELETE /api/network/$id

Retorna: No-content ou Gone

=cut

sub network_DELETE {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(superadmin));

    my $obj = $c->stash->{object}->next;
    $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

    $obj->delete;

    $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}

=pod

listar cidades

GET /api/network

Retorna:

    {
        "networks": [
            {
                "name": "Foo Bar",
            }
        ]
    }

=cut

sub list_GET {
    my ( $self, $c ) = @_;
    my $rs      = $c->stash->{collection};
    my $topic   = $c->req->params->{topic} if $c->req->params->{topic};
    my $user_id = $c->req->params->{user_id} if $c->req->params->{user_id};
    if ($topic) {
        $rs = $rs->search( { topic => $topic } ) if $topic;

    }
    if ($user_id) {
        $rs = $rs->search( { 'network_users.user_id' => $user_id },
            { join => 'network_users' } );

    }
    my @list = $rs->search( undef, { order_by => 'id' } )->as_hashref->all;
    my @objs;

    foreach my $obj (@list) {
        push @objs, {
            (
                map { $_ => $obj->{$_} }
                  qw(
                  id name name_url created_at created_by

                  institute_id domain_name
                  )
            ),
            url => $c->uri_for_action(
                $self->action_for('network'), [ $obj->{id} ]
            )->as_string,
        };
    }

    $self->status_ok( $c, entity => { network => \@objs } );
}

=pod

criar cidade

POST /api/network

Param:

    network.create.name      Texto, Requerido: nome da cidade

Retorna:

    {"name":"Foo Bar","id":3}

=cut

sub list_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(superadmin));

    $c->req->params->{network}{create}{created_by} = $c->user->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ),
      $c->detach
      unless $dm->success;
    my $object = $dm->get_outcome_for('network.create');


    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('network'), [ $object->id ] )
          ->as_string,
        entity => {
            name => $object->name,
            id   => $object->id,
        }
    );

}

with 'Iota::TraitFor::Controller::Search';
1;
