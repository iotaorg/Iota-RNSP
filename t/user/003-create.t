
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(Iota);

use HTTP::Request::Common;
use Package::Stash;
use Path::Class qw(dir);
use Iota::TestOnly::Mock::AuthUser;

my $schema = Iota->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::TestOnly::Mock::AuthUser->new;

$Iota::TestOnly::Mock::AuthUser::_id    = 1;
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

eval {
    $schema->txn_do(
        sub {
            my $city = $schema->resultset('City')->create(
                {
                    uf   => 'SP',
                    name => 'Pederneiras'
                },
            );

            my ( $res, $c );
            ( $res, $c ) = ctx_request(
                POST '/api/user',
                [
                    api_key                        => 'test',
                    'user.create.name'             => 'FooBar',
                    'user.create.email'            => 'foo@invalid',
                    'user.create.password'         => 'foobarquux1',
                    'user.create.password_confirm' => 'foobarquux1',
                ]
            );
            ok( !$res->is_success, 'user invalid' );
            is( $res->code, 400, 'invalid request' );
            ok( $c->stash->{error}{'user.create.email.invalid'},             'email invalid' );
            ok( !$c->stash->{error}{'user.create.name.invalid'},             'name ok' );
            ok( !$c->stash->{error}{'user.create.password.invalid'},         'password ok' );
            ok( !$c->stash->{error}{'user.create.password_confirm.invalid'}, 'password_confirm ok' );

            ( $res, $c ) = ctx_request(
                POST '/api/user',
                [
                    api_key                                 => 'test',
                    'user.create.name'                      => 'Foo Bar',
                    'user.create.email'                     => 'foo@email.com',
                    'user.create.password'                  => 'foobarquux1',
                    'user.create.nome_responsavel_cadastro' => 'nome_responsavel_cadastro',
                    'user.create.password_confirm'          => 'foobarquux1',
                    'user.create.city_id'                   => $city->id,
                    'user.create.role'                      => 'user',

                    'user.create.city_summary' => 'testeteste'
                ]
            );
            ok( $res->is_success, 'user created' );
            is( $res->code, 201, 'user created' );

            ok( my $new_user = $schema->resultset('User')->find( { email => 'foo@email.com' } ), 'user in DB' );
            is( $new_user->nome_responsavel_cadastro, 'nome_responsavel_cadastro', 'nome responsavel ok' );
            is( $new_user->city_summary, 'testeteste', 'city_summary ok' );
            {
                use JSON qw(from_json);
                is( from_json( $res->content )->{name}, $new_user->name, 'same user' );
            }

            like( $res->header('Location'), qr{/api/user/\d+$}, 'location ok' );

            my ($id) = $res->header('Location') =~ /api\/user\/(\d+)$/;
            my $url_user = $res->header('Location');
            use URI;
            my $uri = URI->new( $res->header('Location') );

            $uri->query_form( api_key => 'test' );

            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'user exists' );
            is( $res->code, 200, 'user exists -- 200 Success' );

            ( $res, $c ) = ctx_request(
                POST $url_user . '/arquivo/perfil_XD',
                'Content-Type' => 'form-data',
                Content        => [
                    api_key   => 'test',
                    'arquivo' => ["$Bin/img_teste.gif"],
                ]
            );
            ok( $res->is_success, 'OK' );
            is( $res->code, 200, 'Image created!' );

            my $filename = "user_${id}_perfil_xd_img_teste.gif";

            my $name =
              Iota->config->{private_path} =~ /^\//o
              ? dir( Iota->config->{private_path} )->resolve . '/' . $filename
              : Iota->path_to( $c->config->{private_path}, $filename );

            ok( -e $name, $name . ' image exists' );
            if ( -e $name ) {
                unlink($name) if -e $name;

                ( $res, $c ) = ctx_request(
                    POST $url_user . '/arquivo/perfil_XD',
                    'Content-Type' => 'form-data',
                    Content        => [
                        api_key   => 'test',
                        'arquivo' => ["$Bin/img_teste_2.gif"],
                    ]
                );

                ( $res, $c ) = ctx_request( GET $url_user );
                {
                    my $obj = from_json( $res->content );

                    like( $obj->{files}{perfil_xd}, qr|img_teste_2\.gif|, 'version updated' );
                }
                my $filename = "user_${id}_perfil_xd_img_teste_2.gif";
                $name =
                  Iota->config->{private_path} =~ /^\//o
                  ? dir( Iota->config->{private_path} )->resolve . '/' . $filename
                  : Iota->path_to( $c->config->{private_path}, $filename );

                ok( -e $name, $name . ' image exists' );

                unlink($name) if -e $name;
            }

            ( $res, $c ) = ctx_request(
                POST '/api/user',
                [
                    api_key                        => 'test',
                    'user.create.name'             => 'Foo Bar',
                    'user.create.email'            => 'foo@email.com',
                    'user.create.password'         => 'foobarquux1',
                    'user.create.password_confirm' => 'foobarquux1',
                ]
            );
            ok( !$res->is_success, 'error' );
            is( $res->code, 400, 'user already exists' );

            ( $res, $c ) = ctx_request( GET '/api/user' );

            use JSON qw(from_json);
            my $users = from_json( $res->content );

            foreach ( @{ $users->{users} } ) {
                next unless $_->{name} eq 'Foo Bar';

                delete $_->{url};
                like( delete $_->{id}, qr/^\d+$/, 'have id' );
                is( ref delete $_->{roles}, 'ARRAY', 'roles' );
                delete $_->{institute};
                delete $_->{network};

                my $var = {
                    'nome_responsavel_cadastro' => 'nome_responsavel_cadastro',
                    'cidade'                    => undef,
                    'bairro'                    => undef,
                    'endereco'                  => undef,
                    'name'                      => 'Foo Bar',
                    'active'                    => 1,
                    'estado'                    => undef,
                    'telefone'                  => undef,
                    'email'                     => 'foo@email.com',
                    'city'                      => {
                        'name' => 'Pederneiras',
                        'id'   => $city->id
                    },
                    'telefone_contato' => undef,
                    'cep'              => undef,
                    'email_contato'    => undef
                };
                is_deeply( $_, $var, 'is ok listing' );
            }

            ( $res, $c ) = ctx_request( GET '/api/user?role=superadmin' );

            $users = from_json( $res->content );
            is( $users->{users}[0]{roles}[0], 'superadmin', 'superadmin filter ok' );

            ( $res, $c ) = ctx_request( GET '/api/user?network_id=1' );

            $users = from_json( $res->content );

            is( scalar @{ $users->{users} }, '3', 'filter ok' );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
