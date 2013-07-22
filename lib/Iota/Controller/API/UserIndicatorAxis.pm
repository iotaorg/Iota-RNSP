
package Iota::Controller::API::UserIndicatorAxis;

use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/base') : PathPart('user_indicator_axis') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{collection} = $c->model('DB::UserIndicatorAxis');

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $self->status_bad_request( $c, message => 'invalid.argument' ), $c->detach
      unless $id =~ /^[0-9]+$/;

    $c->stash->{object} = $c->stash->{collection}->search_rs(
        {
            'me.id'      => $id,
            'me.user_id' => $c->req->params->{user_id} || $c->user->id
        }
    );

    $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub user_indicator_axis : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

=pod

=encoding utf-8

GET /api/user_indicator_axis/$id

Retorna:

    {
        "id": "1",
        "name": "Foo Bar",
        "position": 0,
        "items" => [...],
        "created_at": "2012-09-27 18:55:53.480272",
    }

=cut

sub user_indicator_axis_GET {
    my ( $self, $c ) = @_;
    my $object_ref = $c->stash->{object}->search(
        { user_id => $c->req->params->{user_id} || $c->user->id },
        {
            prefetch => ['user_indicator_axis_items'],
            order_by => [ 'me.position', 'user_indicator_axis_items.position' ]
        }
    )->as_hashref->next;

    $self->status_ok(
        $c,
        entity => {
            ( map { $_ => $object_ref->{$_} } qw(name position id user_id created_at) ),

            items => [
                map { { id => $_->{id}, indicator_id => $_->{indicator_id}, position => $_->{position} } }
                  @{ $object_ref->{user_indicator_axis_items} }
            ],
        }
    );
}

=pod

atualizar cidade

POST /api/user_indicator_axis/$id

Retorna:

    user_indicator_axis.update.name      Texto
    user_indicator_axis.update.position  Int

=cut

sub user_indicator_axis_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(user));

    $c->req->params->{user_indicator_axis}{update}{id} = $c->stash->{object}->next->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $obj = $dm->get_outcome_for('user_indicator_axis.update');

    $self->status_accepted(
        $c,
        location => $c->uri_for( $self->action_for('user_indicator_axis'), [ $obj->id ] )->as_string,
        entity => { name => $obj->name, id => $obj->id }
      ),
      $c->detach
      if $obj;
}

=pod

apagar cidade

DELETE /api/user_indicator_axis/$id

Retorna: No-content ou Gone

=cut

sub user_indicator_axis_DELETE {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(user));

    my $obj = $c->stash->{object}->next;
    $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

    $obj->user_indicator_axis_items->delete;

    $obj->delete;

    $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}

=pod

listar os eixos customizados dos indicadores
que podem ser entendidos como "grupos" de indicadores.

GET /api/user_indicator_axis

?indicator_id=xx

Retorna:

    {
        "user_indicator_axis": [
            {
                "name": "Foo Bar",
                "user_id": 1,
                "position":0,
                "items": [
                    {
                        indicator_id: 1,
                        position: 0
                    }
                ]
            }
        ]
    }

=cut

sub list_GET {
    my ( $self, $c ) = @_;

    my @list = $c->stash->{collection}->search(
        {
            ( user_id => $c->req->params->{user_id} || $c->user->id ),

            (
                exists $c->req->params->{indicator_id} && $c->req->params->{indicator_id} =~ /^\d+$/
                ? ( 'user_indicator_axis_items.indicator_id' => $c->req->params->{indicator_id} )
                : ()
            )
        },
        {
            prefetch => ['user_indicator_axis_items'],
            order_by => [ 'me.id', 'me.position', 'user_indicator_axis_items.position' ]
        }
    )->as_hashref->all;
    my @objs;

    foreach my $obj (@list) {
        push @objs, {
            ( map { $_ => $obj->{$_} } qw(id name user_id position) ),

            items => [
                map { { id => $_->{id}, indicator_id => $_->{indicator_id}, position => $_->{position} } }
                  @{ $obj->{user_indicator_axis_items} }
            ],

            url => $c->uri_for_action( $self->action_for('user_indicator_axis'), [ $obj->{id} ] )->as_string,
        };
    }

    $self->status_ok( $c, entity => { user_indicator_axis => \@objs } );
}

=pod

criar cidade

POST /api/user_indicator_axis

Param:


    user_indicator_axis.create.user_id   se nao enviado, eh o user atual
    user_indicator_axis.create.name      Texto, Requerido: nome
    user_indicator_axis.create.position  int

Retorna:

    {"name":"Foo Bar","id":3}

=cut

sub list_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(user));

    $c->req->params->{user_indicator_axis}{create}{user_id} ||= $c->user->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;
    my $object = $dm->get_outcome_for('user_indicator_axis.create');

    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('user_indicator_axis'), [ $object->id ] )->as_string,
        entity => {
            name => $object->name,
            id   => $object->id,
        }
    );

}

with 'Iota::TraitFor::Controller::Search';
1;

