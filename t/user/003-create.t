
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(RNSP::PCS);

use HTTP::Request::Common;
use Package::Stash;

use RNSP::PCS::TestOnly::Mock::AuthUser;

my $schema = RNSP::PCS->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = RNSP::PCS::TestOnly::Mock::AuthUser->new;

$RNSP::PCS::TestOnly::Mock::AuthUser::_id    = 1;
@RNSP::PCS::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

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
                [   api_key                        => 'test',
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
                [   api_key                        => 'test',
                    'user.create.name'             => 'Foo Bar',
                    'user.create.email'            => 'foo@email.com',
                    'user.create.password'         => 'foobarquux1',
                    'user.create.password_confirm' => 'foobarquux1',
                    'user.create.city_id'          => $city->id,
                    'user.create.role'             => 'admin',
                ]
            );
            ok( $res->is_success, 'user created' );
            is( $res->code, 201, 'user created' );

            ok( my $new_user = $schema->resultset('User')->find( { email => 'foo@email.com' } ), 'user in DB' );

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
                Content =>
                [   api_key                        => 'test',
                    'arquivo' => ["$Bin/img_teste.gif"],
                ]
            );
            ok( $res->is_success, 'OK' );
            is( $res->code, 202, 'Image created!' );

            my $name = "$Bin/../../root/static/user/user_${id}_perfil_xd_img_teste.gif";
            ok(-e $name, $name . ' image exists');
            if (-e $name ){
                unlink($name) if -e $name;

                ( $res, $c ) = ctx_request(
                    POST $url_user . '/arquivo/perfil_XD',
                    'Content-Type' => 'form-data',
                    Content =>
                    [   api_key                        => 'test',
                        'arquivo' => ["$Bin/img_teste_2.gif"],
                    ]
                );

                ( $res, $c ) = ctx_request( GET $url_user );
                {
                    my $obj = from_json( $res->content );

                    like( $obj->{files}{perfil_xd}, qr|img_teste_2\.gif|, 'version updated' );
                }
                $name = "$Bin/../../root/static/user/user_${id}_perfil_xd_img_teste_2.gif";
                unlink($name) if -e $name;
            }

            ( $res, $c ) = ctx_request(
                POST '/api/user',
                [   api_key                        => 'test',
                    'user.create.name'             => 'Foo Bar',
                    'user.create.email'            => 'foo@email.com',
                    'user.create.password'         => 'foobarquux1',
                    'user.create.password_confirm' => 'foobarquux1',
                ]
            );
            ok( !$res->is_success, 'error' );
            is( $res->code, 400, 'user already exists' );



            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
