

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

            my $city2 = $schema->resultset('City')->create(
                {
                    uf   => 'XX',
                    name => 'AWS'
                },
            );

        my ( $res, $c ) = ctx_request(
            POST '/api/user',
            [
            api_key                        => 'test',
            'user.create.name'             => 'Foo Bar',
            'user.create.email'            => 'foo@email.com',
            'user.create.password'         => 'foobarquux1',
            'user.create.password_confirm' => 'foobarquux1',
            'user.create.city_id'          => $city->id,
            'user.create.role'             => 'user',
            'user.create.network_id'       => 2
            ]
        );
        ok( $res->is_success, 'user created' );
        is( $res->code, 201, 'user created' );
        ok(
            my $new_user =
            $schema->resultset('User')->find( { email => 'foo@email.com' } ),
            'user in DB'
        );
        is(eval{$new_user->network->name_url}, 'movimento', 'criado como movimento');



        ( $res, $c ) = ctx_request(
            POST '/api/user',
            [
            api_key                        => 'test',
            'user.create.name'             => 'Foo XX',
            'user.create.email'            => 'errorme@email.com',
            'user.create.password'         => 'foobarquux1',
            'user.create.password_confirm' => 'foobarquux1',
            'user.create.role'             => 'user',
            'user.create.city_id'          => $city->id,
            'user.create.network_id'       => 2
            ]
        );

        ok( !$res->is_success, 'user not created' );
        is( $res->code, 400, 'user not created' );
        like($res->content, qr|user.create.network_id.invalid|, 'error na cidade ja tem movimento');

        ( $res, $c ) = ctx_request(
            POST '/api/user',
            [
            api_key                        => 'test',
            'user.create.name'             => 'Foo XX',
            'user.create.email'            => 'noterro@email.com',
            'user.create.password'         => 'foobarquux1',
            'user.create.password_confirm' => 'foobarquux1',
            'user.create.city_id'          => $city->id,
            'user.create.role'             => 'admin',

            ]
        );
        ok( $res->is_success, 'user created na city 1 como admin da rede' );
        is( $res->code, 201, 'user created na city 1 como admin' );

        ( $res, $c ) = ctx_request(
            POST '/api/user',
            [
            api_key                        => 'test',
            'user.create.name'             => 'Foo XX',
            'user.create.email'            => 'errorme@email.com',
            'user.create.password'         => 'foobarquux1',
            'user.create.password_confirm' => 'foobarquux1',
            'user.create.city_id'          => $city2->id,
            'user.create.role'             => 'user',
            'user.create.network_id'       => 2
            ]
        );
        ok( $res->is_success, 'user created na city 2 como movimento' );
        is( $res->code, 201, 'user created na city 2 como movimento' );

        use JSON qw(encode_json);

        # update user
        ( $res, $c ) = ctx_request(
            POST '/api/user/' . $new_user->id,
            [
            api_key                        => 'test',
            'user.update.name'             => 'Foo Bar',
            'user.update.email'            => 'bar@email.com',
            'user.update.network_id'       => undef,

            ]
        );
        ok( $res->is_success, 'user updated ' );
        is( $res->code, 202, 'user updated -- 202 Accepted' );
        ok(
            $new_user =
            $schema->resultset('User')->find( $new_user->id ),
            'user in DB'
        );
        is(eval{$new_user->network}, undef, 'perdeu o movimento');


        ( $res, $c ) = ctx_request(
            POST '/api/user',
            [
            api_key                        => 'test',
            'user.create.name'             => 'Foo XX',
            'user.create.email'            => 'orme@email.com',
            'user.create.password'         => 'foobarquux1',
            'user.create.password_confirm' => 'foobarquux1',
            'user.create.city_id'          => $city->id,
            'user.create.role'             => 'user',
            'user.create.network_id'       => 2
            ]
        );
        ok( $res->is_success, 'user created to city 1 again' );
        is( $res->code, 201, 'user created to city 1 again' );

        ok(
            my $changecity =
            $schema->resultset('User')->find( { email => 'errorme@email.com' } ),
            'user in DB'
        );
        is(eval{$changecity->network->name_url}, 'movimento', 'criado como movimento');

        ( $res, $c ) = ctx_request(
            POST '/api/user/' . $changecity->id,
            [
            api_key                        => 'test',
            'user.update.name'             => 'Foo Bar',
            'user.update.email'            => 'errorme@email.com',
            'user.update.city_id'          => $city->id,
            ]
        );

        ok( !$res->is_success, 'user updated' );
        like($res->content, qr|"user.update.city_id.invalid|, 'user.update.city_id.invalid');

        ( $res, $c ) = ctx_request(
            POST '/api/user/' . $changecity->id,
            [
            api_key                        => 'test',
            'user.update.name'             => 'Foo Bar',
            'user.update.email'            => 'errorme@email.com',
            'user.update.city_id'          => $city->id,
            'user.update.network_id'       => 2,
            ]
        );

        ok( !$res->is_success, 'user updated' );
        like($res->content, qr/"user.update.(network_id|city_id).invalid/, 'user.update.network_id.invalid');


        ( $res, $c ) = ctx_request(
            POST '/api/user/' . $changecity->id,
            [
            api_key                        => 'test',
            'user.update.name'             => 'Foo Bar XXX',
            'user.update.email'            => 'errorme@email.com',
            'user.update.city_id'          => $city->id,
            'user.update.network_id'       => 3,
            ]
        );

        ok( $res->is_success, 'user updated' );

        die 'rollback';
    }
);
};

die $@ unless $@ =~ /rollback/;

done_testing;
