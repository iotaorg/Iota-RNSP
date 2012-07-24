
package RNSP::PCS::Controller::API::User;

use Moose;

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/base') : PathPart('user') : CaptureArgs(0) {
  my ( $self, $c ) = @_;
  $c->stash->{collection} = $c->model('DB::User');
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
  my ( $self, $c, $id ) = @_;
  $c->stash->{object} = $c->stash->{collection}->search_rs( { id => $id } );
  $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub user : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
  my ( $self, $c ) = @_;

}

sub user_GET {
  my ( $self, $c ) = @_;
  my $user  = $c->stash->{object}->next;
  my %attrs = $user->get_inflated_columns;
  $self->status_ok(
    $c,
    entity => {
      roles => [ map { $_->name } $user->roles ],
      $user->city
      ? (
        city => $c->uri_for(
          $c->controller('API::City')->action_for('city'),
          [ $attrs{city_id} ] )->as_string
        )
      : (),
      map { $_ => $attrs{$_}, } qw(name email)
    }
  );
}

sub user_POST {
  my ( $self, $c ) = @_;
  $c->req->params->{user}{update}{id} = $c->stash->{object}->next->id;

  my $dm = $c->model('DataManager');

  $self->status_bad_request( $c, message => 'rooots' ), $c->detach
    unless $dm->success;

  my $user = $dm->get_outcome_for('user.update');

  $self->status_accepted(
    $c,
    location =>
      $c->uri_for( $self->action_for('user'), [ $user->id ] )->as_string,
    entity => { name => $user->name, id => $user->id }
    ),
    $c->detach
    if $user;
}

sub user_DELETE {
  my ( $self, $c ) = @_;
  $c->stash->{object}->delete;

  $self->status_gone( $c, message => 'deleted' );
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}

sub list_GET {
  my ( $self, $c ) = @_;
  $self->status_ok(
    $c,
    entity => {
      users => [
        map {
          +{
            name => $_->{name},
            $_->{city}
            ? (
              city => {
                name => $_->{city}->{name},
                id   => $_->{city}->{id}
              }
              )
            : (),
            url => $c->uri_for_action( $self->action_for('user'), [ $_->{id} ] )
              ->as_string
            }
          } $c->stash->{collection}
          ->search_rs( undef, { prefetch => 'city' } )->as_hashref->all
      ]
    }
  );
}

sub list_POST {
  my ( $self, $c ) = @_;

  $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->user->check_roles(qw(admin));

  my $dm = $c->model('DataManager');

  $self->status_bad_request( $c, message => 'roots' ), $c->detach
    unless $dm->success;
  my $user = $dm->get_outcome_for('user.create');
  $self->status_created(
    $c,
    location => $c->uri_for( $self->action_for('user'), [ $user->id ] )->as_string,
    entity => {
      name => $user->name,
      id   => $user->id,
      $user->city
      ? ( city =>
          { name => $user->city->name, id => $user->city->id } )
      : (),
    }
  );

}

with 'RNSP::PCS::TraitFor::Controller::Search';
1;

