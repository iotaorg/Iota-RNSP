package Iota::Controller::API::User::Region;

use Moose;
use JSON qw (encode_json);
BEGIN { extends 'Catalyst::Controller::REST' }
use Path::Class qw(dir);

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/user/object') : PathPart('region') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{user}       = $c->stash->{object}->next;
    $c->stash->{collection} = $c->stash->{user}->user_regions;

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
    $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub region : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

sub region_GET {
    my ( $self, $c ) = @_;
    my $object_ref = $c->stash->{object}->as_hashref->next;

    $self->status_ok(
        $c,
        entity => {
            (
                map { $_ => $object_ref->{$_} }
                  qw(
                  id
                  created_at
                  region_classification_name
                  )
            )
        }
    );
}

sub region_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));

    my $obj_rs = $c->stash->{object}->next;

    if ( $c->user->id != $obj_rs->user_id && !$c->check_any_user_role(qw(admin superadmin)) ) {
        $self->status_forbidden( $c, message => "access denied", ), $c->detach;
    }

    my $param = $c->req->params->{user}{region}{update};
    $param->{id} = $obj_rs->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $obj = $dm->get_outcome_for('user.region.update');

    $self->status_accepted(
        $c,
        location => $c->uri_for( $self->action_for('region'), [ $c->stash->{user}->id, $obj->id ] )->as_string,
        entity => { id => $obj->id }
      ),

      $c->detach;
}

sub region_DELETE {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));

    my $obj = $c->stash->{object}->next;
    $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

    if ( $c->user->id == $obj->user_id || $c->check_any_user_role(qw(admin superadmin)) ) {
        $obj->delete;
    }

    $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}

sub list_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));

    my $param = $c->req->params->{user}{region}{create};
    $param->{user_id} = $c->stash->{user}->id;

    my $dm = $c->model('DataManager');
    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $object = $dm->get_outcome_for('user.region.create');

    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('region'), [ $c->stash->{user}->id, $object->id ] )->as_string,
        entity => { id => $object->id }
    );

}

sub list_GET {
    my ( $self, $c ) = @_;

    my $query = $c->stash->{collection}->as_hashref;

    my $out = {};
    while ( my $r = $query->next ) {
        push @{ $out->{regions} }, {
            (
                map { $_ => $r->{$_} }
                  qw(
                  id
                  created_at
                  region_classification_name
                  )
            )
        };
    }
    $self->status_ok( $c, entity => $out );

}

1;

