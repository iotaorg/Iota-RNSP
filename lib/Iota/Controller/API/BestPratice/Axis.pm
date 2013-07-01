package Iota::Controller::API::BestPratice::Axis;

use Moose;
use JSON qw (encode_json);
BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/bestpratice/object') : PathPart('axis') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{best_pratice} = $c->stash->{object}->next;
    $c->stash->{collection}   = $c->stash->{best_pratice}->user_best_pratice_axes;

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
    $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub best_pratice : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

sub best_pratice_GET {
    my ( $self, $c ) = @_;
    my $object_ref = $c->stash->{object}->as_hashref->next;

    $self->status_ok(
        $c,
        entity => {
            (
                map { $_ => $object_ref->{$_} }
                  qw(
                  id
                  axis_id
                  user_best_pratice_id
                  )
            )
        }
    );
}

=pod

Apaga o registro da tabela CityAxis

DELETE /api/best_pratice/$id/best_pratice/$id

Retorna: No-content ou Gone

=cut

sub best_pratice_DELETE {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(user admin superadmin ));

    my $obj = $c->stash->{object}->next;
    $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

    $obj->delete;

    $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}

=pod

POST /api/best_pratice/$id/best_pratice


=cut

sub list_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(user admin superadmin ));

    my $param = $c->req->params->{best_pratice}{axis}{create};
    $param->{user_best_pratice_id} = $c->stash->{best_pratice}->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $object = $dm->get_outcome_for('best_pratice.axis.create');

    $self->status_created(
        $c,
        location =>
          $c->uri_for( $self->action_for('best_pratice'), [ $c->stash->{best_pratice}->id, $object->id ] )->as_string,
        entity => { id => $object->id }
    );

}

sub list_GET {
    my ( $self, $c ) = @_;

    my @list = $c->stash->{collection}->as_hashref->all;
    my @objs;

    foreach my $obj (@list) {
        push @objs, {
            (
                (
                    map { $_ => $obj->{$_} }
                      qw(
                      id
                      axis_id
                      user_best_pratice_id),
                ),
            ),
            url =>
              $c->uri_for_action( $self->action_for('best_pratice'), [ $c->stash->{best_pratice}->id, $obj->{id} ] )
              ->as_string,

        };
    }

    $self->status_ok( $c, entity => { axis => \@objs } );
}

1;

