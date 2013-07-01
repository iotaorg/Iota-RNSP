
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

            ( $res, $c ) = ctx_request( GET $reg1_uri );
            my $obj = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [
                    api_key                       => 'test',
                    'variable.create.name'        => 'Foo Bar',
                    'variable.create.cognomen'    => 'foobar',
                    'variable.create.period'      => 'weekly',
                    'variable.create.explanation' => 'a foo with bar',
                    'variable.create.type'        => 'int',
                ]
            );
            ok( $res->is_success, 'variable created!' );
            is( $res->code, 201, 'created!' );

            my $variable = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request(
                POST '/api/indicator',
                [
                    api_key                          => 'test',
                    'indicator.create.name'          => 'Foo Bar',
                    'indicator.create.formula'       => '1 + $' . $variable->{id},
                    'indicator.create.axis_id'       => '1',
                    'indicator.create.explanation'   => 'explanation',
                    'indicator.create.source'        => 'me',
                    'indicator.create.goal_source'   => '@fulano',
                    'indicator.create.chart_name'    => 'pie',
                    'indicator.create.goal_operator' => '>=',
                    'indicator.create.tags'          => 'you,me,she',

                    'indicator.create.observations'     => 'lala',
                    'indicator.create.visibility_level' => 'public',
                ]
            );

            my $indicator = eval { from_json( $res->content ) };

            my $region_url = $reg1_uri . '/value';

            # PUT normal
            my $req = POST $region_url,
              [
                'region.variable.value.put.value'         => '123',
                'region.variable.value.put.variable_id'   => $variable->{id},
                'region.variable.value.put.value_of_date' => '2012-10-10 14:22:44',
                'region.variable.value.put.source'        => 'bazar',
              ];
            $req->method('PUT');
            ( $res, $c ) = ctx_request($req);

            ok( $res->is_success, 'variable value created' );
            is( $res->code, 201, 'value added -- 201 ' );

            # GET
            my $week1_url = $res->header('Location');
            my $uri       = URI->new($week1_url);
            $uri->query_form( api_key => 'test' );
            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'variable exists' );
            is( $res->code, 200, 'variable exists -- 200 Success' );

            my $variable_valu = eval { from_json( $res->content ) };

            is( $variable_valu->{value}, '123', 'variable created with correct value' );
            is( $variable_valu->{value_of_date}, '2012-10-10 14:22:44', 'variable created with correct value date' );

            $req = POST $region_url,
              [
                'region.variable.value.put.value'         => '4456',
                'region.variable.value.put.variable_id'   => $variable->{id},
                'region.variable.value.put.value_of_date' => '2012-10-11 14:22:44',
                'region.variable.value.put.observations'  => 'farinha',
              ];
            $req->method('PUT');
            ( $res, $c ) = ctx_request($req);

            # GET
            is( $week1_url, $res->header('Location'), 'same variable updated!' );
            $uri = URI->new($week1_url);
            $uri->query_form( api_key => 'test' );
            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'variable exists' );
            is( $res->code, 200, 'variable exists -- 200 Success' );

            $variable_valu = eval { from_json( $res->content ) };

            is( $variable_valu->{value},         '4456',                'variable updated with correct value' );
            is( $variable_valu->{observations},  'farinha',             'observations updated' );
            is( $variable_valu->{source},        'bazar',               'observations conserved' );
            is( $variable_valu->{value_of_date}, '2012-10-11 14:22:44', 'variable updated with correct value date' );

            ok( delete $variable_valu->{created_at} );
            is_deeply(
                $variable_valu,
                {
                    cognomen => 'foobar',

                    created_by => {
                        id   => 2,
                        name => 'adminpref'
                    },
                    name          => 'Foo Bar',
                    observations  => 'farinha',
                    region_id     => $reg1->{id},
                    active_value  => 0,
                    generated_by_compute  => undef,
                    source        => 'bazar',
                    type          => 'int',
                    value         => '4456',
                    value_of_date => '2012-10-11 14:22:44'
                },
                'deeply ok'
            );

            $req = POST $region_url, [
                'region.variable.value.put.value'         => '4456',
                'region.variable.value.put.variable_id'   => $variable->{id},
                'region.variable.value.put.value_of_date' => '2012-10-17 14:22:44',    # mas dia 17 eh a proxima
            ];
            $req->method('PUT');
            ( $res, $c ) = ctx_request($req);
            ok( $week1_url ne $res->header('Location'), 'variable change!!' );

            ( $res, $c ) = ctx_request( GET $region_url );
            ok( $res->is_success, 'list the values exists' );
            is( $res->code, 200, 'list the values exists -- 200 Success' );

            my $list = eval { from_json( $res->content ) };

            for my $n ( 0 .. 1 ) {
                for my $w (qw/url id created_at/) {
                    ok( delete $list->{values}[$n]{$w}, 'has ' . $w );
                }
            }

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
                            observations  => "farinha",
                            region_id     => $reg1->{id},
                            source        => "bazar",
                            type          => "int",
                            value         => '4456',
                            value_of_date => "2012-10-11 14:22:44"
                        },
                        {
                            cognomen   => "foobar",
                            created_by => {
                                id   => 2,
                                name => "adminpref"
                            },
                            name          => "Foo Bar",
                            observations  => undef,
                            region_id     => $reg1->{id},
                            source        => undef,
                            type          => "int",
                            value         => '4456',
                            value_of_date => "2012-10-17 14:22:44"
                        },
                    ]
                },
                'deeply ok'
            );

            ( $res, $c ) = ctx_request( GET $region_url . '?valid_from=1990-01-02' );
            ok( $res->is_success, 'list the values exists' );
            is( $res->code, 200, 'list the values exists -- 200 Success' );

            $list = eval { from_json( $res->content ) };
            is_deeply( $list->{values}, [], 'no values in 1990' );

            ( $res, $c ) = ctx_request( GET $region_url . '?user_id=1' );
            ok( $res->is_success, 'list the values exists' );
            is( $res->code, 200, 'list the values exists -- 200 Success' );

            $list = eval { from_json( $res->content ) };
            is_deeply( $list->{values}, [], 'no values for user 1' );

            ( $res, $c ) = ctx_request( GET $region_url . '?variable_id=4' );
            ok( $res->is_success, 'list the values exists' );
            is( $res->code, 200, 'list the values exists -- 200 Success' );

            $list = eval { from_json( $res->content ) };
            is_deeply( $list->{values}, [], 'no values for variable 4' );


            ( $res, $c ) = ctx_request( GET '/api/indicator/'.$indicator->{id}.'/variable/period/2012-10-17?region_id=' . $reg1->{id} );
            is( $res->code, 200, 'list the values exists -- 200 Success' );
            $list = eval { from_json( $res->content ) };
            is_deeply( scalar @{$list->{rows}}, 1);


            ( $res, $c ) = ctx_request( GET '/api/user/'.$Iota::TestOnly::Mock::AuthUser::_id.'/variable?region_id=' . $reg1->{id} . '&is_basic=0' );
            is( $res->code, 200, 'list the values exists -- 200 Success' );
            $list = eval { from_json( $res->content ) };

            is_deeply( scalar @{$list->{variables}}, 1);

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
