package Iota::Controller::API::AxisDim2;

use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/base') : PathPart('axis-dim2') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{collection} = $c->model('DB::AxisDim2');
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $self->status_bad_request( $c, message => 'invalid.argument' ), $c->detach
      unless $id =~ /^[0-9]+$/;

    $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );

    $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub axis : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

sub axis_GET {
    my ( $self, $c ) = @_;
    my $object_ref = $c->stash->{object}->as_hashref->next;

    $self->status_ok( $c, entity => { ( map { $_ => $object_ref->{$_} } qw(name description id created_at) ) } );
}

sub axis_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin));

    $c->req->params->{axis_dim2}{update}{id} = $c->stash->{object}->next->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $obj = $dm->get_outcome_for('axis_dim2.update');

    $self->status_accepted(
        $c,
        location => $c->uri_for( $self->action_for('axis'), [ $obj->id ] )->as_string,
        entity => { name => $obj->name, id => $obj->id }
      ),
      $c->detach
      if $obj;
}

sub axis_DELETE {
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

sub list_GET {
    my ( $self, $c ) = @_;

    my @list = $c->stash->{collection}->as_hashref->all;
    my @objs;

    foreach my $obj (@list) {
        push @objs,
          {
            ( map { $_ => $obj->{$_} } qw(id name description) ),
            url => $c->uri_for_action( $self->action_for('axis'), [ $obj->{id} ] )->as_string,
          };
    }

    $self->status_ok( $c, entity => { axis => \@objs } );
}

sub list_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin));

    $c->req->params->{axis_dim2}{create}{created_by} = $c->user->id;
    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;
    my $object = $dm->get_outcome_for('axis_dim2.create');

    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('axis'), [ $object->id ] )->as_string,
        entity => {
            name => $object->name,
            id   => $object->id,
        }
    );

}

1;

