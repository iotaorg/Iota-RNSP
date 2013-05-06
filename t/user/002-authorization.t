use strict;
use warnings;

use Test::More;
use HTTP::Request::Common;

use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Catalyst::Test qw(Iota);

my $schema = Iota->model('DB');

eval {
    $schema->txn_do(

        sub {

            my ( $res, $c );
            ( $res, $c ) = ctx_request( POST '/api/user', );

            ok( !$res->is_success, 'access denied' );
            like( $res->content, qr/denied/i, 'access denied response' );
            is( $res->code, 403, q{forbidden} );

            my $user = $schema->resultset('User')->create(
                {
                    name     => 'Lord Admin',
                    email    => 'admin@email.com',
                    password => '1234youguessit',
                    city     => $schema->resultset('City')->create(
                        {
                            name => 'Campo Grande',
                            uf   => 'MS',
                        },
                    )
                },
            );
            $user->add_to_roles( { name => 'admin' } );

            ( $res, $c ) = ctx_request(
                POST '/api/login',
                [
                    'user.login.email'    => 'admin@email.com',
                    'user.login.password' => '1234youguessit'
                ],
            );

          SKIP: {
                skip 'needs to check for empty params', 2;
                ok( $res->is_success, 'user ok' );
                is( $res->code, 200, 'status 200 OK' );

                #warn $user->api_key;
                $user->discard_changes;

                #warn $user->api_key;
                ( $res, $c ) = ctx_request( POST '/api/user', [ api_key => $user->api_key ] );
                ok( !$res->is_success, 'fails, but...' );

                is( $res->code, 400, q{...it's not forbidden anymore} );
            }

            die 'rollback';
        }
    );
};

die $@ unless $@ =~ /rollback/;

done_testing;
