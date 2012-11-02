
package RNSP::PCS::Controller::API::UserPublic;

use Moose;

use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/root') : PathPart('public/user') : CaptureArgs(0) {
  my ( $self, $c, $id ) = @_;
  $c->stash->{collection} = $c->model('DB::User');
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
  my ( $self, $c, $id ) = @_;

  $c->stash->{user} = $c->stash->{collection}->search_rs( { id => $id } );

  $c->stash->{user_obj} = $c->stash->{user}->next;

  $c->detach('/error_404') unless defined $c->stash->{user_obj};


}

sub user : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
  my ( $self, $c ) = @_;

}

=pod

=encoding utf-8

Retorna as informações das ultimas versoes das variveis basicas, cidade, foto da capa,

GET /api/public/user/$id

Retorna:

    {
        variaveis => [{
            nome => '',
            valor => '',
            data => ''
        }],
        cidade => {
            pais, uf, cidade, latitude, longitude
        },

    }

=cut

sub user_GET {
    my ( $self, $c ) = @_;

    my $user  = $c->stash->{user_obj};

    my $ret = {};
    do {
        my $rs = $c->model('DB::Variable')->search_rs({
            'values.user_id' => $user->id,
            is_basic => 1
        }, { prefetch => ['values'] } );

        $rs = $rs->as_hashref;
        my $existe = {};
        while(my $r = $rs->next){

            @{$r->{values}} = map {$_} sort {$a->{valid_from} cmp $b->{valid_from}} @{$r->{values}};
            my $valor = pop @{$r->{values}};

            push (@{$ret->{variaveis}}, {
                name => $r->{name},
                cognomen => $r->{cognomen},
                period => $r->{period},
                type => $r->{type},
                last_value => $valor->{value}
            } );
        }

    };

    do {
        my $r = $c->model('DB::City')->search_rs({
            'id' => $user->city_id
        })->as_hashref->next;

        if($r){

            $ret->{cidade} = {
                name => $r->{name},
                uf => $r->{uf},
                pais => $r->{pais},
                latitude => $r->{latitude},
                longitude => $r->{longitude}
            };
        }

    };

    $self->status_ok(
        $c,
        entity => $ret
    );
}


1;

