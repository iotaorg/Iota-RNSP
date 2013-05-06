
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
            my $uri = URI->new($week1_url);
            $uri->query_form( api_key => 'test' );
            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'variable exists' );
            is( $res->code, 200, 'variable exists -- 200 Success' );

            my $variable_valu = eval { from_json( $res->content ) };

            is( $variable_valu->{value}, '123', 'variable created with correct value' );
            is( $variable_valu->{value_of_date}, '2012-10-10 14:22:44', 'variable created with correct value date' );

            $req = POST $region_url, [
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

            is( $variable_valu->{value}, '4456', 'variable updated with correct value' );
            is( $variable_valu->{observations}, 'farinha', 'observations updated' );
            is( $variable_valu->{source}, 'bazar', 'observations conserved' );
            is( $variable_valu->{value_of_date}, '2012-10-11 14:22:44', 'variable updated with correct value date' );

            ok(delete $variable_valu->{created_at});
            is_deeply( $variable_valu, {
                cognomen     =>  'foobar',

                created_by   =>  {
                    id  =>  2,
                    name=>  'adminpref'
                },
                name         =>  'Foo Bar',
                observations =>  'farinha',
                region_id    =>  $reg1->{id},
                source       =>  'bazar',
                type         =>  'int',
                value        =>  '4456',
                value_of_date=>  '2012-10-11 14:22:44'
            }, 'deeply ok');

            $req = POST $region_url, [
                'region.variable.value.put.value'         => '4456',
                'region.variable.value.put.variable_id'   => $variable->{id},
                'region.variable.value.put.value_of_date' => '2012-10-17 14:22:44',    # mas dia 17 eh a proxima
            ];
            $req->method('PUT');
            ( $res, $c ) = ctx_request($req);
            ok( $week1_url ne $res->header('Location'), 'variable change!!' );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
