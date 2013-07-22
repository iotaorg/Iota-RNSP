
package Iota::Controller::API::BestPratice;

use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/base') : PathPart('best_pratice') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{collection} = $c->model('DB::UserBestPratice');

    if ( $c->check_any_user_role(qw(user)) ) {
        $c->stash->{collection} = $c->stash->{collection}->search( { 'me.user_id' => $c->user->id } );
    }

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
        $self->status_bad_request( $c, message => 'invalid.argument' ), $c->detach
      unless $id =~ /^[0-9]+$/;

    $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );

    $c->stash->{object}->count > 0 or $c->detach('/error_404');

    if ( $c->req->method ne 'GET' && $c->check_any_user_role(qw(user)) ) {
        $self->status_forbidden( $c, message => "access denied", ), $c->detach
          unless $c->user->id == $c->stash->{object}->first->user_id;
    }
}

sub best_pratice : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

sub best_pratice_GET {
    my ( $self, $c ) = @_;
    my $object_ref = $c->stash->{object}->search( undef, { prefetch => 'user_best_pratice_axes' } )->as_hashref->next;

    $self->status_ok(
        $c,
        entity => {
            (
                map { $_ => $object_ref->{$_} }
                  qw(
                  id user_id axis_id name description methodology goals
                  schedule results institutions_involved contatcts sources
                  tags)
            ),
            axis =>
              [ map { +{ axis_id => $_->{axis_id}, id => $_->{id} } } @{ $object_ref->{user_best_pratice_axes} } ]

        }
    );
}

sub best_pratice_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));

    $c->req->params->{best_pratice}{update}{id} = $c->stash->{object}->first->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $obj = $dm->get_outcome_for('best_pratice.update');

    $self->status_accepted(
        $c,
        location => $c->uri_for( $self->action_for('best_pratice'), [ $obj->id ] )->as_string,
        entity => { id => $obj->id }
      ),
      $c->detach
      if $obj;
}

=pod

apagar cidade

DELETE /api/best_pratice/$id

Retorna: No-content ou Gone

=cut

sub best_pratice_DELETE {
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

GET /api/best_pratice

Retorna:

    {
        "best_pratices": [
            {

            }
        ]
    }

=cut

sub list_GET {
    my ( $self, $c ) = @_;

    my @list = $c->stash->{collection}->as_hashref->all;
    my @objs;

    foreach my $obj (@list) {
        push @objs, {
            (
                map { $_ => $obj->{$_} }
                  qw(id
                  user_id axis_id name description methodology goals
                  schedule results institutions_involved contatcts sources
                  )
            ),
            url => $c->uri_for_action( $self->action_for('best_pratice'), [ $obj->{id} ] )->as_string,
        };
    }

    $self->status_ok( $c, entity => { best_pratices => \@objs } );
}

=pod

POST /api/best_pratice

=cut

sub list_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));

    $c->req->params->{best_pratice}{create}{user_id} = $c->req->params->{user_id} || $c->user->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;
    my $object = $dm->get_outcome_for('best_pratice.create');

    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('best_pratice'), [ $object->id ] )->as_string,
        entity => {

            id => $object->id,
        }
    );

}

with 'Iota::TraitFor::Controller::Search';
1;

