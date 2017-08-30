
package Iota::Controller::API::User;

use Moose;
use JSON;
use Path::Class qw(dir);

use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/base') : PathPart('user') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{collection} = $c->model('DB::User');

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $self->status_bad_request( $c, message => 'invalid.argument' ), $c->detach
      unless $id =~ /^[0-9]+$/;

    my $url = $c->req->uri->path;
    if (   ( $url =~ /variable_config$/ || $url =~ /variable_config\/\d+$/ )
        && $c->user->id != $id
        && $c->req->method eq 'GET' ) {

        $self->status_forbidden( $c, message => "access denied for $id | log is " . $c->user->id ), $c->detach
          unless $c->check_any_user_role(qw(user));

    }
    else {
        $self->status_forbidden( $c, message => "access denied", ), $c->detach
          unless $c->user->id == $id || $c->check_any_user_role(qw(admin superadmin));
    }

    $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
    $c->stash->{object}->count > 0 or $c->detach('/error_404');

}

sub cap_user_file : Chained('object') : PathPart('arquivo') : CaptureArgs(1) {
    my ( $self, $c, $classe ) = @_;
    $c->stash->{classe} = $classe;
}

sub user_file : Chained('cap_user_file') : PathPart('') : Args(0) : ActionClass('REST') {
}

sub user_file_POST {
    my ( $self, $c ) = @_;

    my $classe = $c->stash->{classe};
    my $t      = new Text2URI();

    $classe = $t->translate( substr( $classe, 0, 15 ) );
    $classe ||= 'perfil';

    $c->res->content_type('application/json; charset=utf8');

    my $upload = $c->req->upload('arquivo');

    if ($upload) {

        if ( $classe =~ /(imagem_cidade|logo_movimento|perfil_xd)/ ) {

            my $exiv = `which exiv2 2>&1`;
            chomp($exiv);

            if ( `which 2>&1` eq '' && $exiv ) {
                my $x   = $upload->tempname;
                my $ret = `$exiv $x 2>&1`;

                if ( $ret !~ /Image size/ ) {
                    $c->res->body( to_json( { error => 'not an image' } ) );
                    $c->detach;
                }
            }
        }

        my $user_id = $c->stash->{object}->next->id;
        my $filename =
          sprintf( 'user_%i_%s_%s', $user_id, $classe, substr( $t->translate( $upload->basename ), 0, 200 ) );

        my $private_path =
          $c->config->{private_path} =~ /^\//o
          ? dir( $c->config->{private_path} )->resolve . '/' . $filename
          : Iota->path_to( $c->config->{private_path}, $filename );

        unless ( $upload->copy_to($private_path) ) {
            $c->res->body( to_json( { error => "Copy failed: $!" } ) );
            $c->detach;
        }
        chmod 0644, $private_path;

        my $public_url = $c->uri_for( $c->config->{public_url} . '/' . $filename )->as_string;

        # nao trocar por $c->user->obj por causa dos testes
        my $file = $c->model('DB::User')->find($user_id)->add_to_user_files(
            {
                class_name   => $classe,
                public_url   => $public_url,
                private_path => $private_path
            }
        );

        $c->res->body( to_json( { class_name => $classe, id => $file->id, location => $public_url } ) );

    }
    else {
        $c->res->body( to_json( { error => 'no upload found' } ) );
    }

    $c->detach;
}

sub user_file_DELETE {
    my ( $self, $c ) = @_;

    my $classe = $c->stash->{classe};
    my $t      = new Text2URI();

    $classe = $t->translate( substr( $classe, 0, 15 ) );
    $classe ||= 'perfil';

    my $user_id = $c->stash->{object}->next->id;
    $c->model('DB::User')->find($user_id)->user_files->search( { class_name => $classe, } )->delete;

    $self->status_no_content($c);
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

sub _get_user_type {
    my ( $self, $user ) = @_;
    my %roles = map { ( ref $_ eq '' ? $_ : $_->name ) => 1 } $user->roles;

    return 'superadmin' if exists $roles{superadmin};
    return 'admin'      if exists $roles{admin};
    return 'user'       if exists $roles{user};

    return 'none';
}

use Storable qw/nfreeze thaw/;
use Redis;
my $redis = Redis->new;

sub user_GET {
    my ( $self, $c ) = @_;

    my @campos_cadastro = qw/id
      name
      email

      nome_responsavel_cadastro
      estado
      telefone
      email_contato
      telefone_contato
      cidade
      bairro
      cep
      endereco
      city_summary
      active
      cur_lang
      regions_enabled
      can_create_indicators
      /;
    my @campos_cadastro_comp = ( @campos_cadastro, qw/institute_id metadata/ );

    my $cache_key = $c->stash->{object}->search(
        undef,
        {
            select => [
                \(
                        "md5( array_agg(  coalesce(user_files.public_url, 'null') || coalesce(me.city_id::text, 'null') || "
                      . join( '||', map { "coalesce(me.${_}::text, 'null')" } @campos_cadastro_comp )
                      . ' order by user_files.id )::text)'
                )
            ],
            join         => 'user_files',
            as           => ['md5'],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    )->next;
    $cache_key = $cache_key->{md5};
    $cache_key = "user-get-$cache_key";

    my $stash = $redis->get($cache_key);

    if ($stash) {
        $stash = thaw($stash);
    }
    else {

        my $user = $c->stash->{object}->search( undef, { prefetch => [ 'institute', 'user_files' ] } )->next;

        my %attrs = $user->get_inflated_columns;
        $stash = {
            roles     => [ map { $_->name } $user->roles ],
            user_type => $self->_get_user_type($user),
            files     => {
                map { $_->class_name => $_->public_url }
                  $user->user_files->search( undef, { order_by => 'created_at' } )
            },

            ( map { $_ => $attrs{$_}, } @campos_cadastro ),
            created_at => $attrs{created_at}->datetime,
            ( metadata => $user->build_metadata ),

            (
                $user->institute && $user->institute
                ? (
                    institute => {
                        (
                            map { $_ => $user->institute->$_ }
                              qw /
                              users_can_edit_value
                              users_can_edit_groups
                              can_use_custom_css
                              can_use_custom_pages
                              bypass_indicator_axis_if_custom
                              hide_empty_indicators
                              fixed_indicator_axis_id
                              can_create_indicators
                              can_use_regions/
                        ),

                        name => $user->institute->name,
                        id   => $user->institute->id,

                        metadata => $user->institute->build_metadata
                    }
                  )
                : ( institute => undef )
            ),

            (
                $user->city
                ? ( city =>
                      $c->uri_for( $c->controller('API::City')->action_for('city'), [ $attrs{city_id} ] )->as_string )
                : ()
            ),

            networks => [
                map {
                    my $net = $_;
                    +{
                        ( map { $_ => $net->$_ } qw/name name_url id/ ),
                        url =>
                          $c->uri_for( $c->controller('API::Network')->action_for('network'), [ $net->id ] )->as_string,
                      }
                } $user->networks
            ],

        };

        $redis->setex( $cache_key, 360, nfreeze($stash) );
    }
    $self->status_ok( $c, entity => $stash );
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
    user.update.network_id          int, nao Requerido


    nome_responsavel_cadastro, estado, telefone, email_contato, telefone_contato, cidade, bairro, cep, endereco,
Retorna:

    { name => '', id => '' }

=cut

sub user_POST {
    my ( $self, $c ) = @_;
    $c->req->params->{user}{update}{id} = $c->stash->{object}->next->id;

    $self->status_bad_request( $c, message => 'campo user.update.network_id' ), $c->detach
      if exists $c->req->params->{user}{update}{network_id};

    $c->req->params->{user}{update}{network_ids} = 'DO_NOT_UPDATE'
      unless exists $c->req->params->{user}{update}{network_ids};

    my $dm = $c->model('DataManager');
    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $user = $dm->get_outcome_for('user.update');

    $self->status_accepted(
        $c,
        location => $c->uri_for( $self->action_for('user'), [ $user->id ] )->as_string,
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

    #  $user->user_roles->delete;
    #  $user->sessions->delete;
    $user->update( { active => 0, city_id => undef } );

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
      unless $c->check_any_user_role(qw(admin superadmin));

    my $rs =
      $c->stash->{collection}
      ->search_rs( { 'me.active' => 1 }, { prefetch => [ 'city', 'institute', { user_roles => 'role' } ] } );

    if ( $c->req->params->{role} ) {
        $rs = $rs->search( { 'role.name' => $c->req->params->{role} } );
    }

    if ( $c->req->params->{network_id} ) {

        $rs =
          $rs->search( { 'network_users.network_id' => $c->req->params->{network_id} }, { join => 'network_users' } );
    }

    $self->status_ok(
        $c,
        entity => {
            users => [
                map {

                    +{
                        name   => $_->{name},
                        id     => $_->{id},
                        email  => $_->{email},
                        active => $_->{active},

                        nome_responsavel_cadastro => $_->{nome_responsavel_cadastro},
                        estado                    => $_->{estado},
                        telefone                  => $_->{telefone},
                        email_contato             => $_->{email_contato},
                        telefone_contato          => $_->{telefone_contato},
                        cidade                    => $_->{cidade},
                        bairro                    => $_->{bairro},
                        cep                       => $_->{cep},
                        endereco                  => $_->{endereco},
                        cur_lang                  => $_->{cur_lang},

                        $_->{city}
                        ? (
                            city => {
                                name => $_->{city}->{name},
                                id   => $_->{city}->{id}
                            }
                          )
                        : ( city => undef ),

                        $_->{user_roles}
                        ? ( roles => [ map { $_->{role}->{name} } @{ $_->{user_roles} } ] )
                        : ( roles => [] ),

                        exists $_->{institute}
                        ? (
                            institute => {
                                users_can_edit_value  => $_->{network}{institute}{users_can_edit_value},
                                users_can_edit_groups => $_->{network}{institute}{users_can_edit_groups},
                                can_use_custom_css    => $_->{network}{institute}{can_use_custom_css},
                                can_use_custom_pages  => $_->{network}{institute}{can_use_custom_pages},
                                name                  => $_->{network}{institute}{name},
                                id                    => $_->{network}{institute}{id},
                            }
                          )
                        : ( institute => undef ),

                        url => $c->uri_for_action( $self->action_for('user'), [ $_->{id} ] )->as_string
                      }
                } $rs->as_hashref->all
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

    $c->req->params->{user}{create}{role} ||= 'user';
    if ( $c->req->params->{user}{create}{role} eq 'user' ) {
        my @foo = $c->user->networks ? $c->user->networks->all : ();
        if (@foo) {
            $c->req->params->{user}{create}{network_id} ||= join ',', map { $_->id } @foo;
        }
        else {
            # tests...
            $c->req->params->{user}{create}{network_id} ||= $c->user->network_id;
        }
    }

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $user = $dm->get_outcome_for('user.create');
    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('user'), [ $user->id ] )->as_string,
        entity => {
            name => $user->name,
            id   => $user->id,
            $user->city
            ? ( city => { name => $user->city->name, id => $user->city->id } )
            : (),
        }
    );

}

sub kml_file : Chained('object') : PathPart('kml') : Args(0) ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub kml_file_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));
    my $upload = $c->req->upload('arquivo');

    eval {
        if ($upload) {
            my $user_id = $c->user->id;

            $c->logx( 'Enviou KML ' . $upload->basename );

            my $file = $c->model('KML')->process(
                user_id => $user_id,
                upload  => $upload,
                schema  => $c->model('DB'),
                app     => $c
            );

            $c->res->body( to_json($file) );

        }
        else {
            die "no upload found\n";
        }
    };

    print STDERR " >>>>> $@" if $@;
    $c->res->body( to_json( { error => "$@" } ) ) if $@;

    $c->detach;

}

with 'Iota::TraitFor::Controller::Search';
1;

