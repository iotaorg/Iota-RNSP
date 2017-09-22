
package Iota::Controller::API::Variable;

use Moose;
use JSON qw(encode_json);

use Text2URI;
my $t = Text2URI->new();

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/base') : PathPart('variable') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{collection} = $c->model('DB::Variable');

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $self->status_bad_request( $c, message => 'invalid.argument' ), $c->detach
      unless $id =~ /^[0-9]+$/;

    $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
    $c->stash->{variable} = $c->stash->{object}->first;

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
        "source": "God",
        "is_basic": 0,
        "period": "yearly",
        "name": "Foo Bar",
        "created_at": "2013-02-08 18:41:32.975254",
        "measurement_unit": {
            "short_name": "km",
            "name": "Quilometro",
            "id": 1
        },
        "explanation": "a foo with bar",
        "cognomen": "foobar",
        "type": "int",
        "created_by": {
            "name": "admin",
            "id": 1
        }
    }

=cut

sub variable_GET {
    my ( $self, $c ) = @_;
    my $object_ref =
      $c->stash->{object}->search( undef, { prefetch => [ 'owner', 'measurement_unit', 'image_user_file' ] } )
      ->as_hashref->next;

    $self->status_ok(
        $c,
        entity => {
            created_by => { map { $_ => $object_ref->{owner}{$_} } qw(name id) },

            image_user_file => $object_ref->{image_user_file}
            ? { map { $_ => $object_ref->{image_user_file}->{$_} } qw(public_url id) }
            : undef,

            (
                map { $_ => $object_ref->{$_} }
                  qw(name type cognomen explanation source period is_basic short_name display_order created_at)
            ),

            measurement_unit => $object_ref->{measurement_unit}
            ? { ( map { $_ => $object_ref->{measurement_unit}{$_} } qw(name short_name id) ), }
            : undef
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
    variable.update.measurement_unit Texto



=cut

sub variable_POST {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{logged_user};

    unless ( $c->check_any_user_role('user') && $user->can_create_indicators ) {
        $self->status_forbidden( $c, message => "access denied", ), $c->detach
          unless $c->check_any_user_role(qw(admin superadmin));
    }

    if ( $c->user->obj->institute && $c->user->obj->institute->build_metadata->{hide_cognomen} ) {
        $c->req->params->{variable}{update}{cognomen} = $t->translate( $c->req->params->{variable}{update}{name}, '_' );
    }

    $c->req->params->{variable}{update}{id} = $c->stash->{variable}->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $obj = $dm->get_outcome_for('variable.update');

    $c->logx( 'Atualizou variavel ' . $obj->name );
    $self->status_accepted(
        $c,
        location => $c->uri_for( $self->action_for('variable'), [ $obj->id ] )->as_string,
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

    my $user = $c->stash->{logged_user};
    my $obj  = $c->stash->{variable};

    if ( $c->check_any_user_role('user') && $user->can_create_indicators ) {
        $self->status_forbidden( $c, message => "access denied", ), $c->detach
          if $obj->user_id != $user->id;
    }
    else {
        $self->status_forbidden( $c, message => "access denied", ), $c->detach
          unless $c->check_any_user_role(qw(admin superadmin));
    }

    $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

    $c->model('DB')->schema->txn_do(
        sub {
            $obj->user_variable_configs->delete;
            $obj->delete;
        }
    );

    if ($@) {
        $self->status_bad_request( $c, message => "You can't delete this variable. Delete values first." ), $c->detach;
    }

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
                "measurement_unit":"km",
                "created_by": {
                    "name": "admin",
                    "id": 1
                }
            },
            ...
        ]
    }

=cut

use Storable qw/nfreeze thaw/;
use Redis;
my $redis = Redis->new;

sub list_GET {
    my ( $self, $c ) = @_;

    my $rs = $c->stash->{collection};

    $c->req->params->{use} ||= 'list';
    my $is_user = $c->check_any_user_role('user');

    if ( $c->req->params->{use} eq 'edit' && $is_user ) {
        $rs = $rs->search( { 'me.user_id' => $c->user->id } );
    }

    unless ( $c->req->params->{all_variables} ) {
        if ( $c->req->params->{use} eq 'list' && $is_user ) {

            my @user_ids = ( $c->user->id );

            my @networks = $c->user->networks ? $c->user->networks->all : ();

            my $indicators_rs = $c->model('DB::Indicator')->filter_visibilities(
                networks_ids => [ map { $_->id } @networks ],
                users_ids    => \@user_ids,
            )->get_column('id')->as_query;

            my $variables_id_rs =
              $c->model('DB::IndicatorVariable')->search( { indicator_id => { 'in' => $indicators_rs } } )
              ->get_column('variable_id')->as_query;

            $rs = $rs->search(
                {
                    -or => [
                        'me.id'      => { 'in' => $variables_id_rs },
                        'me.user_id' => $c->user->id
                    ]
                }
            );
        }
    }

    my $cache_key = $rs->search(
        {},
        {
            select => [
                \"md5( array_agg(me.name || me.explanation || me.cognomen || coalesce(me.is_basic::text, 'null') || me.period::text order by me.id)::text)"
            ],
            as           => ['md5'],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    )->next;
    $cache_key = $cache_key->{md5};
    $cache_key = $cache_key ? "variable-list_GET-$cache_key" : rand . rand . rand;

    my $stash = $redis->get($cache_key);

    if ($stash) {
        $stash = thaw($stash);
    }
    else {
        my @list = $rs->search_rs( undef, { prefetch => [ 'owner', 'measurement_unit' ] } )->as_hashref->all;
        my @objs;
        my $base = $c->uri_for_action( $self->action_for('variable'), [':id:'] )->as_string;

        foreach my $obj (@list) {
            push @objs, {

                created_by => { map { $_ => $obj->{owner}{$_} } qw(name id) },

                ( map { $_ => $obj->{$_} } qw(id name type cognomen explanation source period is_basic created_at) ),

                url => do { my $copy = $base; $copy =~ s/:id:/$obj->{id}/; $copy },

                measurement_unit => $obj->{measurement_unit}
                ? { ( map { $_ => $obj->{measurement_unit}{$_} } qw(name short_name id) ), }
                : undef

            };
        }
        $stash = { variables => \@objs };
        $redis->setex( $cache_key, 86400, nfreeze($stash) );

    }

    $self->status_ok( $c, entity => $stash );
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
    variable.update.measurement_unit Texto

Retorna:

    {"name":"Foo Bar","id":3}

=cut

sub list_POST {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{logged_user};
    unless ( $c->check_any_user_role('user') && $user->can_create_indicators ) {
        $self->status_forbidden( $c, message => "access denied", ), $c->detach
          unless $c->check_any_user_role(qw(admin superadmin));
    }

    if ( $c->user->obj->institute && $c->user->obj->institute->build_metadata->{hide_cognomen} ) {
        $c->req->params->{variable}{create}{cognomen} = $t->translate( $c->req->params->{variable}{create}{name}, '_' );
    }

    $c->req->params->{variable}{create}{user_id} = $c->user->id;
    $c->req->params->{variable}{create}{user_type} = Iota::Controller::API::User::_get_user_type( undef, $user );

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;
    my $object = $dm->get_outcome_for('variable.create');
    $c->logx( 'Adicionou variavel ' . $object->name );

    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('variable'), [ $object->id ] )->as_string,
        entity => {
            name => $object->name,
            id   => $object->id,

        }
    );

}

with 'Iota::TraitFor::Controller::Search';
1;

