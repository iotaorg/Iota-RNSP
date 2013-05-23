
use strict;
use warnings;

use Test::More;
use JSON qw(from_json);

use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Catalyst::Test q(Iota);

use HTTP::Request::Common qw(GET POST DELETE PUT);
use Package::Stash;

use Iota::TestOnly::Mock::AuthUser;

my $schema = Iota->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::TestOnly::Mock::AuthUser->new;

$Iota::TestOnly::Mock::AuthUser::_id    = 2;
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

eval {
    $schema->txn_do(
        sub {
            my ( $res, $c );
            ( $res, $c ) = ctx_request(
                POST '/api/city',
                [
                    api_key            => 'test',
                    'city.create.name' => 'FooBar',

                ]
            );
            ok( !$res->is_success, 'invalid request' );
            is( $res->code, 400, 'invalid request' );

            ( $res, $c ) = ctx_request(
                POST '/api/city',
                [
                    api_key                 => 'test',
                    'city.create.name'      => 'Foo Bar',
                    'city.create.state_id'  => 1,
                    'city.create.latitude'  => 5666.55,
                    'city.create.longitude' => 1000.11,
                ]
            );
            ok( $res->is_success, 'city created!' );
            is( $res->code, 201, 'created!' );

            my $city_uri = $res->header('Location');
            ( $res, $c ) = ctx_request(
                POST $city_uri . '/region',
                [
                    api_key                          => 'test',
                    'city.region.create.name'        => 'a region',
                    'city.region.create.description' => 'with no description',
                ]
            );

            ok( $res->is_success, 'region created!' );
            is( $res->code, 201, 'region created!' );

            my $reg1_uri = $res->header('Location');
            my $reg1 = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request( GET $reg1_uri );
            my $obj = eval { from_json( $res->content ) };

            is_deeply(
                $obj,
                {
                    city => {
                        name     => 'Foo Bar',
                        name_uri => 'foo-bar',
                        pais     => 'br',
                        uf       => 'SP'
                    },
                    depth_level    => 2,
                    automatic_fill => 0,
                    description    => 'with no description',
                    name           => 'a region',
                    name_url       => 'subprefeitura:a-region',
                    upper_region   => undef
                },
                'created ok'
            );

            ( $res, $c ) = ctx_request(
                POST $city_uri . '/region',
                [
                    api_key                           => 'test',
                    'city.region.create.name'         => 'foobar',
                    'city.region.create.description'  => 'description',
                    'city.region.create.upper_region' => $reg1->{id},
                ]
            );

            ok( $res->is_success, 'region created!' );
            is( $res->code, 201, 'region created!' );

            my $reg2_uri = $res->header('Location');
            my $reg2 = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request( GET $reg2_uri );
            $obj = eval { from_json( $res->content ) };

            is_deeply(
                $obj,
                {
                    city => {
                        name     => 'Foo Bar',
                        name_uri => 'foo-bar',
                        pais     => 'br',
                        uf       => 'SP'
                    },
                    depth_level    => 3,
                    description    => 'description',
                    name           => 'foobar',
                    automatic_fill => 0,
                    name_url       => 'foobar',
                    upper_region   => {
                        id       => $reg1->{id},
                        name     => 'a region',
                        name_url => 'subprefeitura:a-region',
                    }
                },
                'created ok'
            );

            ( $res, $c ) = ctx_request( GET $city_uri . '/region' );
            $obj = eval { from_json( $res->content ) };

            is( @{ $obj->{regions} }, 2, 'total match' );

            ( $res, $c ) = ctx_request(
                POST $reg2_uri,
                [
                    api_key                   => 'test',
                    'city.region.update.name' => 'xxx',
                ]
            );

            ok( $res->is_success, 'region updated!' );
            is( $res->code, 202, 'region updated!' );

            ( $res, $c ) = ctx_request( GET $reg2_uri );
            $obj = eval { from_json( $res->content ) };

            is_deeply(
                $obj,
                {
                    city => {
                        name     => 'Foo Bar',
                        name_uri => 'foo-bar',
                        pais     => 'br',
                        uf       => 'SP'
                    },
                    depth_level    => 3,
                    description    => 'description',
                    name           => 'xxx',
                    automatic_fill => 0,
                    name_url       => 'xxx',
                    upper_region   => {
                        id       => $reg1->{id},
                        name     => 'a region',
                        name_url => 'subprefeitura:a-region',
                    }
                },
                'updated ok'
            );

            ( $res, $c ) = ctx_request( DELETE $reg2_uri );

            ok( $res->is_success, 'region deleted!' );

            ( $res, $c ) = ctx_request( GET $city_uri . '/region' );
            $obj = eval { from_json( $res->content ) };

            is( @{ $obj->{regions} }, 1, 'total match' );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
