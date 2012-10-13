
package RNSP::PCS::Controller::API::Axis;

use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/base') : PathPart('axis') : CaptureArgs(0) {
  my ( $self, $c ) = @_;
  $c->stash->{collection} = $c->model('DB::Axis');


}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
  my ( $self, $c, $id ) = @_;
  $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
  $c->stash->{axis} = $c->stash->{object}->first;

  $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub axis : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
  my ( $self, $c ) = @_;

}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}


=pod

listar os eixos

GET /api/axis

Retorna:

    {
        "axis": [
            {
                "id": "1",
                "name": "a foo with bar",
            },
            ...
        ]
    }

=cut

sub list_GET {
  my ( $self, $c ) = @_;

    my @list = $c->stash->{collection}->as_hashref->all;
    my @objs;

    foreach my $obj (@list){
        push @objs, {

            (map { $_ => $obj->{$_} } qw(id name)),

        }
    }
    $self->status_ok(
        $c,
        entity => {
        axis => \@objs
        }
    );
}




with 'RNSP::PCS::TraitFor::Controller::Search';
1;

