
package RNSP::PCS::Controller::API::Indicator;

use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/base') : PathPart('indicator') : CaptureArgs(0) {
  my ( $self, $c ) = @_;
  $c->stash->{collection} = $c->model('DB::Indicator');

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
  my ( $self, $c, $id ) = @_;
  $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
  $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub indicator : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
  my ( $self, $c ) = @_;

}

=pod

=encoding utf-8

detalhe da variavel

GET /api/indicator/$id

Retorna:

    {
        "created_at": "2012-08-20 03:24:39.379529",
        "formula": "$a + $b",
        "goal": "1",
        "name": "xx",
        "axis": "Y",
        "url": "http://localhost/api/indicator/32",
        "created_by": {
            "name": "admin",
            "id": 1
        }
    },

=cut

sub indicator_GET {
  my ( $self, $c ) = @_;
  my $object_ref  = $c->stash->{object}->search(undef, {prefetch => ['owner']})->as_hashref->next;

  $self->status_ok(
    $c,
    entity => {
      created_by => {
        map { $_ => $object_ref->{owner}{$_} } qw(name id)
      },
      (map { $_ => $object_ref->{$_} } qw(name goal axis formula created_at))
    }
  );
}

=pod

atualizar variavel

POST /api/indicator/$id

Retorna:

    indicator.update.name         Texto: Nome
    indicator.update.formula      Texto: formula das variaveis
    indicator.update.goal         Texto: numero que se quer chegar
    indicator.update.axis         Texto: (talvez seja a categoria)


=cut

sub indicator_POST {
  my ( $self, $c ) = @_;
    $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->check_user_roles(qw(admin));


  $c->req->params->{indicator}{update}{id} = $c->stash->{object}->next->id;

  my $dm = $c->model('DataManager');

  $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
    unless $dm->success;

  my $obj = $dm->get_outcome_for('indicator.update');

  $self->status_accepted(
    $c,
    location =>
      $c->uri_for( $self->action_for('indicator'), [ $obj->id ] )->as_string,
        entity => { name => $obj->name, id => $obj->id }
    ),
    $c->detach
    if $obj;
}


=pod

apagar variavel

DELETE /api/indicator/$id

Retorna: No-content ou Gone

=cut

sub indicator_DELETE {
  my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->check_user_roles(qw(admin));


  my $obj = $c->stash->{object}->next;
  $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

  $obj->delete;

  $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}


=pod

listar variaveis

GET /api/indicator

Retorna:

    {
        "users": [
            {
                "created_at": "2012-08-20 03:24:39.379529",
                "formula": "$a + $b",
                "goal": "1",
                "name": "BB",
                "axis": "Y",
                "url": "http://localhost/api/indicator/32",
                "created_by": {
                    "name": "admin",
                    "id": 1
                }
            },
            ...
        ]
    }

=cut

sub list_GET {
  my ( $self, $c ) = @_;

    my @list = $c->stash->{collection}->search_rs( undef, { prefetch => 'owner' } )->as_hashref->all;
    my @objs;

    foreach my $obj (@list){
        push @objs, {


            created_by => {
                map { $_ => $obj->{owner}{$_} } qw(name id)
            },

            (map { $_ => $obj->{$_} } qw(id name goal axis formula created_at)),
            url => $c->uri_for_action( $self->action_for('indicator'), [ $obj->{id} ] )->as_string,

        }
    }
    $self->status_ok(
        $c,
        entity => {
        indicators => \@objs
        }
    );
}


=pod

criar variavel

POST /api/indicator

Param:

    indicator.create.name        Texto, Requerido: Nome
    indicator.create.formula     Texto, Requerido: formula das variaveis
    indicator.create.goal        Texto, Requerido: numero que se quer chegar
    indicator.create.axis        Texto, Requerido: (talvez seja a categoria)

Retorna:

    {"name":"Foo Bar","id":3}


=cut

sub list_POST {
  my ( $self, $c ) = @_;
  $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->check_user_roles(qw(admin));


  $c->req->params->{indicator}{create}{user_id} = $c->user->id;

  my $dm = $c->model('DataManager');

  $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
    unless $dm->success;
  my $object = $dm->get_outcome_for('indicator.create');

  $self->status_created(
    $c,
    location => $c->uri_for( $self->action_for('indicator'), [ $object->id ] )->as_string,
    entity => {
      name => $object->name,
      id   => $object->id,

    }
  );

}

with 'RNSP::PCS::TraitFor::Controller::Search';
1;

