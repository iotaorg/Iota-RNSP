
use strict;
use warnings;
use URI;
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

            ( $res, $c ) = ctx_request(
                POST $city_uri . '/region',
                [
                    api_key                          => 'test',
                    'city.region.create.name'        => 'new region',
                    'city.region.create.description' => 'aaaa',
                ]
            );

            ok( $res->is_success, 'region created!' );
            is( $res->code, 201, 'region created!' );

            my $reg2_uri = $res->header('Location');
            my $reg2 = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request( GET $reg1_uri );
            my $obj = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [
                    api_key                       => 'test',
                    'variable.create.name'        => 'Foo Bar',
                    'variable.create.cognomen'    => 'foobar',
                    'variable.create.period'      => 'yearly',
                    'variable.create.explanation' => 'a foo with bar',
                    'variable.create.type'        => 'int',
                ]
            );
            ok( $res->is_success, 'variable created!' );
            is( $res->code, 201, 'created!' );

            my $variable = eval { from_json( $res->content ) };


            my $region_url1 = $reg1_uri . '/value';

            # PUT normal
            my $req = POST $region_url1,
              [
                'region.variable.value.create.value'         => '123',
                'region.variable.value.create.variable_id'   => $variable->{id},
                'region.variable.value.create.value_of_date' => '2012-10-10 14:22:44',
                'region.variable.value.create.source'        => 'bazar',
              ];
            ( $res, $c ) = ctx_request($req);

            ok( $res->is_success, 'variable value created' );
            is( $res->code, 201, 'value added -- 201 ' );


            ( $res, $c ) = ctx_request( GET $region_url1 );
            ok( $res->is_success, 'list the values exists' );
            is( $res->code, 200, 'list the values exists -- 200 Success' );

            my $list = eval { from_json( $res->content ) };
            delete $list->{values}[0]{created_at};
            delete $list->{values}[0]{url};
            delete $list->{values}[0]{id};

            is_deeply(
                $list,
                {
                    values => [
                        {
                            cognomen => "foobar",

                            created_by => {
                                id   => 2,
                                name => "adminpref"
                            },
                            name          => "Foo Bar",
                            observations  => undef,
                            region_id     => $reg1->{id},
                            source        => "bazar",
                            type          => "int",
                            value         => '123',
                            value_of_date => "2012-10-10 14:22:44"
                        }
                    ]
                },
                'deeply ok'
            );


            my $region_url2 = $reg2_uri . '/value';

            # PUT normal
            $req = POST $region_url2,
              [
                'region.variable.value.create.value'         => '123',
                'region.variable.value.create.variable_id'   => $variable->{id},
                'region.variable.value.create.value_of_date' => '2012-10-10 14:22:44',
                'region.variable.value.create.source'        => 'bazar',
              ];
            ( $res, $c ) = ctx_request($req);
            ok( $res->is_success, 'variable value created' );
            is( $res->code, 201, 'value added -- 201 ' );


            ( $res, $c ) = ctx_request( GET $region_url2 );
            ok( $res->is_success, 'list the values exists' );
            is( $res->code, 200, 'list the values exists -- 200 Success' );

            $list = eval { from_json( $res->content ) };
            delete $list->{values}[0]{created_at};
            delete $list->{values}[0]{url};
            delete $list->{values}[0]{id};

            is_deeply(
                $list,
                {
                    values => [
                        {
                            cognomen => "foobar",

                            created_by => {
                                id   => 2,
                                name => "adminpref"
                            },
                            name          => "Foo Bar",
                            observations  => undef,
                            region_id     => $reg2->{id},
                            source        => "bazar",
                            type          => "int",
                            value         => '123',
                            value_of_date => "2012-10-10 14:22:44"
                        }
                    ]
                },
                'deeply ok'
            );



            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
