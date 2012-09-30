
package RNSP::PCS::Controller::API::Variable;

use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/base') : PathPart('variable') : CaptureArgs(0) {
  my ( $self, $c ) = @_;
  $c->stash->{collection} = $c->model('DB::Variable');


}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
  my ( $self, $c, $id ) = @_;
  $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );



  $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub variable : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
  my ( $self, $c ) = @_;

}

=pod

=encoding utf-8

detalhe da variavel

GET /api/variable/$id

Retorna:

    {
        "created_at": "2012-08-20 03:15:18.897994",
        "explanation": "a foo with bar",
        "cognomen": "foobar",
        "name": "Foo Bar",
        "type": "int",
        "source":"foo",
        "period":"semana",
        "is_basic": "1",
        "created_by": {
            "name": "admin",
            "id": 1
        }
    }

=cut

sub variable_GET {
  my ( $self, $c ) = @_;
  my $object_ref  = $c->stash->{object}->search(undef, {prefetch => ['owner']})->as_hashref->next;

  $self->status_ok(
    $c,
    entity => {
      created_by => {
        map { $_ => $object_ref->{owner}{$_} } qw(name id)
      },
      (map { $_ => $object_ref->{$_} } qw(name type cognomen explanation source period is_basic created_at))
    }
  );
}

=pod

atualizar variavel

POST /api/variable/$id

Retorna:

    variable.update.name        Texto: Nome
    variable.update.cognomen    Texto: Apelido
    variable.update.explanation Texto: Explicacao da variavel
    variable.update.type        Texto: Tipo (int,str ou num)
    variable.update.is_basic    Boolean: se aparece ou nao no formulario de formulas
    variable.update.period      Texto
    variable.update.source      Texto

=cut

sub variable_POST {
  my ( $self, $c ) = @_;

  $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->check_user_roles(qw(admin));

  $c->req->params->{variable}{update}{id} = $c->stash->{object}->next->id;

  my $dm = $c->model('DataManager');

  $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
    unless $dm->success;

  my $obj = $dm->get_outcome_for('variable.update');

  $self->status_accepted(
    $c,
    location =>
      $c->uri_for( $self->action_for('variable'), [ $obj->id ] )->as_string,
        entity => { name => $obj->name, id => $obj->id }
    ),
    $c->detach
    if $obj;
}


=pod

apagar variavel

DELETE /api/variable/$id

Retorna: No-content ou Gone

=cut

sub variable_DELETE {
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

GET /api/variable

Retorna:

    {
        "users": [
            {
                "created_at": "2012-08-20 03:24:39.379529",
                "explanation": "a foo with bar",
                "url": "http://localhost/api/variable/32",
                "cognomen": "foobar",
                "name": "Foo Bar",
                "source":"foo",
                "period":"semana",
                "type": "int",
                "is_basic": "1",
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

            (map { $_ => $obj->{$_} } qw(id name type cognomen explanation source period is_basic created_at)),
            url => $c->uri_for_action( $self->action_for('variable'), [ $obj->{id} ] )->as_string,

        }
    }
    $self->status_ok(
        $c,
        entity => {
        variables => \@objs
        }
    );
}


=pod

criar variavel

POST /api/variable

Param:

    variable.create.name        Texto, Requerido: Nome
    variable.create.cognomen    Texto, Requerido: Apelido
    variable.create.explanation Texto, Requerido: Explicacao da variavel
    variable.create.type        Texto, Requerido: Tipo (int,str ou num)
    variable.create.is_basic    Boolean: se aparece ou nao no formulario de formulas
    variable.create.period      Texto: semana,dia ou mes (etc..) que a variavel eh atualizada
    variable.create.source      Texto: origem da variavel


Retorna:

    {"name":"Foo Bar","id":3}

=cut

sub list_POST {
  my ( $self, $c ) = @_;

  $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->check_user_roles(qw(admin));

  $c->req->params->{variable}{create}{user_id} = $c->user->id;

  my $dm = $c->model('DataManager');

  $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
    unless $dm->success;
  my $object = $dm->get_outcome_for('variable.create');

  $self->status_created(
    $c,
    location => $c->uri_for( $self->action_for('variable'), [ $object->id ] )->as_string,
    entity => {
      name => $object->name,
      id   => $object->id,

    }
  );

}

with 'RNSP::PCS::TraitFor::Controller::Search';
1;

