
package Iota::Controller::API::UserIndicatorAxis::Item;

use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/userindicatoraxis/object') : PathPart('item') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{axis}       = $c->stash->{object}->next;
    $c->stash->{collection} = $c->stash->{axis}->user_indicator_axis_items;

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
        $self->status_bad_request( $c, message => 'invalid.argument' ), $c->detach
      unless $id =~ /^[0-9]+$/;

    $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id, } );

    $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub user_indicator_axis_item : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

=pod

=encoding utf-8

GET /api/user_indicator_axis/$id/item/$id

Retorna:

    {
        id
        "indicator_id": 1,
        "position": 1
    }

=cut

sub user_indicator_axis_item_GET {
    my ( $self, $c ) = @_;

    my $object_ref = $c->stash->{object}->search( undef, { order_by => ['me.position'] } )->as_hashref->next;

    $self->status_ok( $c, entity => { ( map { $_ => $object_ref->{$_} } qw(position indicator_id id) ) } );
}

=pod

atualizar cidade

POST /api/user_indicator_axis/$id/item/$id

Retorna:

    user_indicator_axis_item.update.position  Int

=cut

sub user_indicator_axis_item_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(user));

    my $axis_id = $c->req->params->{user_indicator_axis_item}{update}{id} = $c->stash->{object}->next->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $obj = $dm->get_outcome_for('user_indicator_axis_item.update');

    $self->status_accepted(
        $c,
        location => $c->uri_for( $self->action_for('user_indicator_axis_item'), [ $axis_id, $obj->id ] )->as_string,
        entity => { id => $obj->id }
      ),
      $c->detach
      if $obj;
}

=pod

apagar cidade

DELETE /api/user_indicator_axis/$id/item/$id

Retorna: No-content ou Gone

=cut

sub user_indicator_axis_item_DELETE {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(user));

    my $obj = $c->stash->{object}->next;
    $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

    $obj->delete;

    $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}

=pod

listar os eixos customizados dos indicadores
que podem ser entendidos como "grupos" de indicadores.

GET /api/user_indicator_axis/$id/item

Retorna:

    {
        "user_indicator_axis_item": [
            {
                    {
                        indicator_id: 1,
                        position: 0,
                        id : 1
                    }
                ]
            }
        ]
    }

=cut

sub list_GET {
    my ( $self, $c ) = @_;

    my @list = $c->stash->{collection}->search(
        undef,
        {
            prefetch => ['user_indicator_axis_items'],
            order_by => [ 'me.position', 'user_indicator_axis_items.position' ]
        }
    )->as_hashref->all;
    my @objs;

    foreach my $obj (@list) {
        push @objs, {
            ( map { $_ => $obj->{$_} } qw(id indicator_id position) ),

            url => $c->uri_for_action( $self->action_for('user_indicator_axis_item'), [ $obj->{id} ] )->as_string,
        };
    }

    $self->status_ok( $c, entity => { user_indicator_axis_items => \@objs } );
}

=pod

criar cidade

POST /api/user_indicator_axis/$id/item

Param:


    user_indicator_axis_item.create.position  int
    user_indicator_axis_item.create.indicator_id  int

Retorna:

    {"name":"Foo Bar","id":3}

=cut

sub list_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(user));

    $c->req->params->{user_indicator_axis_item}{create}{user_indicator_axis_id} = $c->stash->{axis}->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;
    my $object = $dm->get_outcome_for('user_indicator_axis_item.create');

    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('user_indicator_axis_item'), [ $c->stash->{axis}->id, $object->id ] )
          ->as_string,
        entity => { id => $object->id, }
    );

}

with 'Iota::TraitFor::Controller::Search';
1;

