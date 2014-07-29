
package Iota::Controller::API::City;

use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/base') : PathPart('city') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{collection} = $c->model('DB::City');

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $self->status_bad_request( $c, message => 'invalid.argument' ), $c->detach
      unless $id =~ /^[0-9]+$/;

    $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
    $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub city : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

=pod

=encoding utf-8

detalhe da cidade

GET /api/city/$id

Retorna:

    {
        "uf": "XU",
        "created_at": "2012-09-27 18:55:53.480272",
        "longitude": "1000.11",
        "pais": "USA",
        "latitude": "5666.55",
        "name": "Foo Bar"
    }

=cut

sub city_GET {
    my ( $self, $c ) = @_;
    my $object_ref = $c->stash->{object}->as_hashref->next;

    $self->status_ok(
        $c,
        entity => {
            (
                map { $_ => $object_ref->{$_} }
                  qw(name uf pais latitude longitude name_uri state_id country_id created_at
                  telefone_prefeitura endereco_prefeitura bairro_prefeitura
                  cep_prefeitura nome_responsavel_prefeitura email_prefeitura summary
                  )
            )
        }
    );
}

=pod

atualizar cidade

POST /api/city/$id

Retorna:

    city.update.name      Texto
    city.update.uf        Texto
    city.update.pais      Texto
    city.update.latitude  Double
    city.update.longitude Double

=cut

sub city_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin));

    $c->req->params->{city}{update}{id} = $c->stash->{object}->next->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $obj = $dm->get_outcome_for('city.update');

    $self->status_accepted(
        $c,
        location => $c->uri_for( $self->action_for('city'), [ $obj->id ] )->as_string,
        entity => { name => $obj->name, id => $obj->id }
      ),
      $c->detach
      if $obj;
}

=pod

apagar cidade

DELETE /api/city/$id

Retorna: No-content ou Gone

=cut

sub city_DELETE {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin));

    my $obj = $c->stash->{object}->next;
    $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

    $c->model('DB')->resultset('User')->search( { city_id => $obj->id } )->update( { city_id => undef } );

    $obj->delete;

    $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}

=pod

listar cidades

GET /api/city

Retorna:

    {
        "cities": [
            {
                "longitude": "1000.11",
                "name": "Foo Bar",
                "uf": "XU",
                "created_at": "2012-09-27 18:54:59.15137",
                "pais": "USA",
                "latitude": "5666.55",
                "url": "http://localhost/api/city/9",
                "id": 9,

            }
        ]
    }

=cut

sub list_GET {
    my ( $self, $c ) = @_;

    my @list =
      $c->stash->{collection}
      ->search( undef, { prefetch => [ { current_users => { 'user' => { 'user_roles' => 'role' } } } ] } )
      ->as_hashref->all;
    my @objs;
    foreach my $obj (@list) {
        push @objs, {

            (
                map { $_ => $obj->{$_} }
                  qw(id name uf pais latitude longitude name_uri state_id country_id
                  telefone_prefeitura endereco_prefeitura bairro_prefeitura
                  cep_prefeitura nome_responsavel_prefeitura email_prefeitura summary
                  created_at)
            ),

            current_users => [
                map {
                    my $t = $_;
                    {
                        user => {
                            id         => $t->{user}{id},
                            name       => $t->{user}{name},
                            network_id => $t->{user}{network_id},
                            roles      => [ map { $_->{role}{name} } @{ $t->{user}{user_roles} } ]
                        }
                    }
                } @{ $obj->{current_users} }
            ],

            url => $c->uri_for_action( $self->action_for('city'), [ $obj->{id} ] )->as_string,
        };
    }

    $self->status_ok( $c, entity => { cities => \@objs } );
}

=pod

criar cidade

POST /api/city

Param:

    city.create.name      Texto, Requerido: nome da cidade
    city.create.uf        Texto, Requerido: 2 letras (SP, RJ, etc..)
    city.create.pais      Texto, padrao 'Brasil'
    city.create.latitude  Double
    city.create.longitude Double


Retorna:

    {"name":"Foo Bar","id":3}

=cut

sub list_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin));

    $c->req->params->{city}{create}{user_id} = $c->user->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;
    my $object = $dm->get_outcome_for('city.create');

    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('city'), [ $object->id ] )->as_string,
        entity => {
            name => $object->name,
            id   => $object->id,

        }
    );

}

with 'Iota::TraitFor::Controller::Search';
1;

