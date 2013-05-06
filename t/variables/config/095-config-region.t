
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Catalyst::Test q(Iota);

use HTTP::Request::Common qw(GET POST DELETE PUT);
use Package::Stash;

use Iota::TestOnly::Mock::AuthUser;

my $schema = Iota->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::TestOnly::Mock::AuthUser->new;

$Iota::TestOnly::Mock::AuthUser::_id    = 1;
use JSON qw(from_json);
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin user /;

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

            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [
                    api_key                => 'test',
                    'variable.create.name' => 'FooBar',
                ]
            );
            ok( !$res->is_success, 'invalid request' );
            is( $res->code, 400, 'invalid request' );

            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [
                    api_key                               => 'test',
                    'variable.create.name'                => 'Foo Bar',
                    'variable.create.cognomen'            => 'foobar',
                    'variable.create.explanation'         => 'a foo with bar',
                    'variable.create.type'                => 'int',
                    'variable.create.period'              => 'yearly',
                    'variable.create.source'              => 'God',
                    'variable.create.measurement_unit_id' => '1',
                ]
            );
            ok( $res->is_success, 'variable created!' );
            is( $res->code, 201, 'created!' );
            use URI;
            my $uri = URI->new( $res->header('Location') );
            $uri->query_form( api_key => 'test' );

            my $variable = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'varible exists' );
            is( $res->code, 200, 'varible exists -- 200 Success' );


            my $url_user = '/api/user/' . $Iota::TestOnly::Mock::AuthUser::_id . '/variable_region_config';

            ( $res, $c ) = ctx_request(
                POST $url_user,
                [
                    api_key                                              => 'test',
                    'user.variable_region_config.create.variable_id'          => $variable->{id},
                    'user.variable_region_config.create.region_id'          => $reg1->{id},
                    'user.variable_region_config.create.display_in_home' => '0',
                ]
            );

            ok( $res->is_success, 'indicator created!' );
            is( $res->code, 201, 'created!' );

            my $config_id = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request(
                POST $url_user,
                [
                    api_key                                              => 'test',
                    'user.variable_region_config.create.variable_id'          => $variable->{id},
                    'user.variable_region_config.create.region_id'          => $reg1->{id},
                    'user.variable_region_config.create.display_in_home' => '1',
                ]
            );
            ok( !$res->is_success, '2 conf indicator not created!' );
            is( $res->code, 400, 'not created!' );
            like( $res->content, qr|variable_id\.invalid|, 'invalid' );

            ( $res, $c ) = ctx_request( GET $url_user . '/' . $config_id->{id} );
            ok( $res->is_success, 'indicator get!' );
            is( $res->code, 200, 'created!' );

            my $config = eval { from_json( $res->content ) };
            is( $config->{display_in_home}, '0', 'display_in_home: ok' );

            ( $res, $c ) = ctx_request(
                POST $url_user . '/' . $config_id->{id},
                [
                    api_key                                              => 'test',
                    'user.variable_region_config.update.display_in_home' => '1',
                ]
            );
            ok( $res->is_success, 'indicator updated!' );
            is( $res->code, 202, 'updated!' );

            ( $res, $c ) = ctx_request( GET $url_user . '/' . $config_id->{id} );
            $config = eval { from_json( $res->content ) };
            is( $config->{display_in_home}, '1', 'display_in_home: ok' );

            ( $res, $c ) = ctx_request( GET $url_user . '?variable_id=' . $variable->{id} . '&region_id='.$reg1->{id} );
            my $config2 = eval { from_json( $res->content ) };
            is( $config2->{id}, $config_id->{id}, 'pesquisa funcionando' );

            ( $res, $c ) = ctx_request( DELETE $url_user . '/' . $config_id->{id} );
            ok( $res->is_success, 'indicator deleted!' );
            is( $res->code, 204, 'deleted!' );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
