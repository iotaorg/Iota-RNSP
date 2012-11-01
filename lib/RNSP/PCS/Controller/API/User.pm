
package RNSP::PCS::Controller::API::User;

use Moose;

use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/base') : PathPart('user') : CaptureArgs(0) {
  my ( $self, $c ) = @_;
  $c->stash->{collection} = $c->model('DB::User');

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
  my ( $self, $c, $id ) = @_;

  $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->user->id == $id || $c->check_any_user_role(qw(admin));

  $c->stash->{object} = $c->stash->{collection}->search_rs( { id => $id } );
  $c->stash->{object}->count > 0 or $c->detach('/error_404');


}

sub user_img : Chained('object') : PathPart('imagem') : Args(0) : ActionClass('REST') {
}

sub user_img_POST {
    my ( $self, $c ) = @_;

    my $upload = $c->req->upload('imagem');
    if ($upload){

        my ($ext) = $upload->basename =~ /\.([a-z]+)$/i;


        my $filename = sprintf('user_%i.%s',
            $c->stash->{object}->next->id,
            $ext
        );
        $upload->copy_to(  RNSP::PCS->path_to( $c->config->{root_images} , $filename ));

        $c->config->{root_images} =~ s/^root//;
        $self->status_ok( $c, entity => {ok => 1, url => $c->uri_for($c->config->{root_images} . '/' . $filename)->as_string } );
    }else{
        $self->status_bad_request( $c, message => 'no upload found');
    }
}



sub user : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
  my ( $self, $c ) = @_;

}

=pod

=encoding utf-8

detalhe do usuario

GET /api/user/$id

Retorna:

    {
        roles => [foo],
        city => {..},
        name => 'x',
        email => 'y'
    }

=cut

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

=pod

atualizar usuario

POST /api/user/$id

Param:

    user.update.name                Texto, Requerido: Nome completo do usuário
    user.update.email               Texto, Requerido: Email válido
    user.update.password            Texto, Requerido: Senha maior que 6 caracteres contendo letras, números e símbolos
    user.update.confirm_password    Texto, Requerido: Mesma senha anterior, para confirmação
    user.update.role                Texto, Não Requerido: qual o role dele (admin,user,app)

    user.update.city_id             Int, Requerido: qual a cidade ele pertence
    user.update.prefeito            0 ou 1, Nao Requerido: eh prefeito?
    user.update.movimento           0 ou 1, Nao Requerido: eh movimento?

Retorna:

    { name => '', id => '' }

=cut

sub user_POST {
  my ( $self, $c ) = @_;
  $c->req->params->{user}{update}{id} = $c->stash->{object}->next->id;

  my $dm = $c->model('DataManager');

  $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
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


=pod

apagar usuario

DELETE /api/user/$id

Retorna: No-content ou Gone

=cut

sub user_DELETE {
  my ( $self, $c ) = @_;

  my $user = $c->stash->{object}->next;
  $self->status_gone( $c, message => 'deleted' ), $c->detach unless $user;

  $user->user_roles->delete;
  $user->sessions->delete;
  $user->delete;

  $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}


=pod

listar usuarios

GET /api/user

Retorna:

    {   users => [
            { name => 'JOHANSSON', email => 'ae@bor.ai', id => -1, city => { name => 'SP', id => 1}},
            ...
        ]
    }
=cut

sub list_GET {
  my ( $self, $c ) = @_;

  $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->check_any_user_role(qw(admin));

  $self->status_ok(
    $c,
    entity => {
      users => [
        map {
          +{
            name => $_->{name},
            email => $_->{email},
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


=pod

criar usuario

POST /api/user

Param:

    user.create.name                Texto, Requerido: Nome completo do usuário
    user.create.email               Texto, Requerido: Email válido
    user.create.password            Texto, Requerido: Senha maior que 6 caracteres contendo letras, números e símbolos
    user.create.confirm_password    Texto, Requerido: Mesma senha anterior, para confirmação
    user.create.role                Texto, Não Requerido: qual o role dele (admin,user,app)

    user.create.city_id             Int, Nao Requerido: qual a cidade ele pertence
    user.create.prefeito            0 ou 1, Nao Requerido: eh prefeito?
    user.create.movimento           0 ou 1, Nao Requerido: eh movimento?

    * Persona 1: admin
    * Persona 2: user
    * Persona 3: app

Retorna:

    { name => 'JOHANSSON', id => -1, city => { name => 'SP', id => 1}}

=cut

sub list_POST {
  my ( $self, $c ) = @_;


  my $dm = $c->model('DataManager');

  $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
    unless $dm->success;

  $c->req->params->{user}{create}{role} ||= 'user';

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

