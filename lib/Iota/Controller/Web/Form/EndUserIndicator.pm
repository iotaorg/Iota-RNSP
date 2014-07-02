package Iota::Controller::Web::Form::EndUserIndicator;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST' }

use utf8;
use JSON::XS;

sub base : Chained('/web/form/root') PathPart('end-user-indicator') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{collection} = $c->model('DB::EndUserIndicator');

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $self->status_bad_request( $c, message => 'invalid.argument' ), $c->detach
      unless $id =~ /^[0-9]+$/;

    $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );

    $c->stash->{object}->count > 0 or $c->detach('/error_404');

}

sub end_user_indicator : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

sub end_user_indicator_GET {
    my ( $self, $c ) = @_;
    my $object_ref = $c->stash->{object}->as_hashref->next;

    $self->status_ok(
        $c,
        entity => {
            (
                map { $_ => $object_ref->{$_} }
                  qw(
                  id end_user_id indicator_id all_users
                  )
            ),

        }
    );
}

sub end_user_indicator_DELETE {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->user;

    my $obj = $c->stash->{object}->first;
    $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      if $c->check_any_user_role(qw(user)) && $obj->user_id != $c->user->id;

    $obj->end_user_indicator_users->delete;

    $obj->delete;

    $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

sub list_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->user;

    $c->req->params->{end_user_indicator}{create}{network_id}  = $c->stash->{network}->id;
    $c->req->params->{end_user_indicator}{create}{end_user_id} = $c->user->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;
    my $object = $dm->get_outcome_for('end_user_indicator.create');

    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('end_user_indicator'), [ $object->id ] )->as_string,
        entity => {
            id => $object->id,
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
