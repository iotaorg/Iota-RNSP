
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
                {   type => 'prefeitura',
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
                    'user.create.city_id'          => $city->id
                ]
            );
            ok( $res->is_success, 'user created' );
            is( $res->code, 201, 'user created' );

            ok( my $new_user = $schema->resultset('User')->find( { email => 'foo@email.com' } ), 'user in DB' );

            {
                use JSON qw(decode_json);
                is( decode_json( $res->content )->{name}, $new_user->name, 'same user' );
            }
            like( $res->header('Location'), qr{/api/user/\d+$}, 'location ok' );

            use URI;
            my $uri = URI->new( $res->header('Location') );
            $uri->query_form( api_key => 'test' );

            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'user exists' );
            is( $res->code, 200, 'user exists -- 200 Success' );

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
