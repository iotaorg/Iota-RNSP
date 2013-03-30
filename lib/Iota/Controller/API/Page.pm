
package Iota::Controller::API::Page;

use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/base') : PathPart('page') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{collection} = $c->model('DB::UserPage');


}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );

    $c->stash->{object}->count > 0 or $c->detach('/error_404');

    if ($c->req->method ne 'GET' && $c->check_any_user_role(qw(user))){
        $self->status_forbidden( $c, message => "access denied", ), $c->detach
            unless $c->user->id == $c->stash->{object}->first->user_id;
    }
}

sub page : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

sub page_GET {
    my ( $self, $c ) = @_;
    my $object_ref  = $c->stash->{object}->as_hashref->next;

    $self->status_ok(
        $c,
        entity => {
        (map { $_ => $object_ref->{$_} } qw(id user_id created_at published_at title title_url content))
        }
    );
}


sub page_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
        unless $c->check_any_user_role(qw(admin superadmin user));

    $c->req->params->{page}{update}{id} = $c->stash->{object}->first->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
        unless $dm->success;

    my $obj = $dm->get_outcome_for('page.update');

    $self->status_accepted(
        $c,
        location =>
        $c->uri_for( $self->action_for('page'), [ $obj->id ] )->as_string,
            entity => { id => $obj->id }
        ),
        $c->detach
        if $obj;
}


=pod

apagar cidade

DELETE /api/page/$id

Retorna: No-content ou Gone

=cut

sub page_DELETE {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
        unless $c->check_any_user_role(qw(admin superadmin user));

    my $obj = $c->stash->{object}->first;
    $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
        if $c->check_any_user_role(qw(user)) && $obj->user_id != $c->user->id;

    $obj->delete;

    $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}


=pod

listar cidades

GET /api/page

Retorna:

    {
        "pages": [
            {

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
            (map { $_ => $obj->{$_} } qw(id user_id created_at published_at title title_url content)),
            url => $c->uri_for_action( $self->action_for('page'), [ $obj->{id} ] )->as_string,
        }
    }

    $self->status_ok(
        $c,
        entity => {
        pages => \@objs
        }
    );
}


=pod

POST /api/page

=cut

sub list_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
        unless $c->check_any_user_role(qw(admin superadmin user));

    $c->req->params->{page}{create}{user_id} = $c->req->params->{user_id} || $c->user->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
        unless $dm->success;
    my $object = $dm->get_outcome_for('page.create');

    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('page'), [ $object->id ] )->as_string,
        entity => {

            id   => $object->id,
        }
    );

}

with 'Iota::TraitFor::Controller::Search';
1;

