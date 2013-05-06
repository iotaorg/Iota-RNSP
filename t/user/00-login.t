
use strict;
use warnings;

use Test::More;
use Catalyst::Test q(Iota);

use HTTP::Request::Common;

use JSON qw(from_json);
my $schema = Iota->model('DB');
eval {
    $schema->txn_do(
        sub {
            my ( $res, $c );

            # non-existent user
            ( $res, $c ) = ctx_request(
                POST '/api/login',
                [
                    'user.login.email'    => 'foo@email.com',
                    'user.login.password' => '1234'
                ],
            );

            ok( !$res->is_success, 'user is not registered' );
            is( $res->code, 400, 'status 400' );
            like( $res->content, qr/invalid/i, 'invalid request' );

            # user exists
            my $obj = $schema->resultset('User')->create(
                {
                    name     => 'FooX Bar Quux',
                    email    => 'foo@email.com',
                    password => '12345',
                    city     => $schema->resultset('City')->create(
                        {
                            name => 'Campo Grande',
                            uf   => 'MS',
                        }
                    )
                },
            );
            $obj->add_to_roles( { name => 'user' } );
            ( $res, $c ) = ctx_request(
                POST '/api/login',
                [
                    'user.login.email'    => 'foo@email.com',
                    'user.login.password' => '12345'
                ],
            );

            ok( $res->is_success, 'user ok' );
            is( $res->code, 200, 'status 200 OK' );
            ok( my $decoded_response = from_json( $res->content ),   'valid json' );
            ok( my $api_key          = $decoded_response->{api_key}, 'api_key ok' );
            is( $decoded_response->{roles}[0], 'user', 'user role' );

            my $cookie;
            $cookie = $res->header('Set-Cookie');

            ( $res, $c ) = ctx_request( GET '/api/logout?api_key=' . $api_key, Cookie => $cookie );
            ok( $res->is_success, 'logout success' );
            is( $res->code, 200, q{status 200 OK} );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
