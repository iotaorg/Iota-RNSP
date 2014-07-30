
use strict;
use warnings;
use URI;
use Test::More;
use JSON qw(from_json);

use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Catalyst::Test q(Iota);

my $variable;
my $indicator;
my $city_uri;
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

            my $inst = $schema->resultset('Institute')->create(
                {
                    active_me_when_empty => 1,
                    name                 => 'name',
                    short_name           => 'short_name',

                }
            );
            my $net = $schema->resultset('Network')->create(
                {
                    name         => 'name',
                    name_url     => 'short_name',
                    domain_name  => 'domain_name',
                    created_by   => 1,
                    institute_id => $inst->id,
                }
            );

            my $u = $schema->resultset('User')->create(
                {
                    name            => 'name',
                    email           => 'email@email.com',
                    institute_id    => $inst->id,
                    password        => '!!!',
                    regions_enabled => 1
                }
            );
            $u->add_to_user_roles( { role => { name => 'admin' } } );
            $u->add_to_network_users( { network_id => $net->id } );

            $ENV{HARNESS_ACTIVE_institute_id} = $inst->id;

            $Iota::TestOnly::Mock::AuthUser::_id = $u->id;

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

            $city_uri = $res->header('Location');
            ( $res, $c ) = ctx_request(
                POST $city_uri . '/region',
                [
                    api_key                                     => 'test',
                    'city.region.create.name'                   => 'a region',
                    'city.region.create.description'            => 'with no description',
                    'city.region.create.subregions_valid_after' => '2020-01-01',
                ]
            );

            ok( $res->is_success, 'region created!' );
            is( $res->code, 201, 'region created!' );

            my $reg1_uri = $res->header('Location');
            my $reg1 = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request(
                POST $city_uri . '/region',
                [
                    api_key                           => 'test',
                    'city.region.create.name'         => 'second region',
                    'city.region.create.upper_region' => $reg1->{id},
                    'city.region.create.description'  => 'with Description',
                ]
            );

            ok( $res->is_success, 'region created!' );
            is( $res->code, 201, 'region created!' );

            my $reg2_uri = $res->header('Location');
            ( $res, $c ) = ctx_request( GET $reg2_uri );
            my $reg2 = eval { from_json( $res->content ) };
            ( $reg2->{id} ) = $reg2_uri =~ /\/([0-9]+)$/;

            ( $res, $c ) = ctx_request(
                POST $city_uri . '/region',
                [
                    api_key                           => 'test',
                    'city.region.create.name'         => 'second region x',
                    'city.region.create.upper_region' => $reg1->{id},
                    'city.region.create.description'  => 'with Descriptionx',
                ]
            );

            ok( $res->is_success, 'region created!' );
            is( $res->code, 201, 'region created!' );

            my $reg3_uri = $res->header('Location');
            ( $res, $c ) = ctx_request( GET $reg3_uri );
            my $reg3 = eval { from_json( $res->content ) };
            ( $reg3->{id} ) = $reg3_uri =~ /\/([0-9]+)$/;

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
                    'variable.create.type'        => 'num',
                ]
            );
            ok( $res->is_success, 'variable created!' );
            is( $res->code, 201, 'created!' );

            $variable = eval { from_json( $res->content ) };

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

            $indicator = eval { from_json( $res->content ) };
            note 'primeiro cenario: sem dados no banco, regiao a partir de 2005 começa a ter subregioes';
            eval {
                $schema->txn_do(
                    sub {
                        my $ii;
                        &update_region_valid_time( $reg1, undef );
                        &add_value( $reg1_uri, '100', '2002' );
                        &add_value( $reg1_uri, '130', '2003' );
                        &add_value( $reg1_uri, '150', '2004' );

                        &update_region_valid_time( $reg1, '2005-01-01' );
                        &add_value( $reg2_uri, '80', '2005' );
                        &add_value( $reg3_uri, '82', '2005' );

                        &add_value( $reg2_uri, '95', '2006' );
                        $Iota::IndicatorData::DEBUG = 1;
                        &add_value( $reg3_uri, '94', '2006' );

=pod
                        $ii = &get_indicator( $reg1, '2002' );
                        is_deeply( $ii, ['101'], 'valor de 2002 ativo' );
                        #$ii = &get_indicator( $reg1, '2002', 1 );

                        #is_deeply( $ii, [], 'nao existe valor active_value=0 para 2002' );

                        $ii = &get_indicator( $reg1, '2003' );
                        is_deeply( $ii, ['131'], 'valor de 2003 ativo' );
                        #$ii = &get_indicator( $reg1, '2003', 1 );
                        #is_deeply( $ii, [], 'nao existe valor active_value=0 para 2003' );

                        $ii = &get_indicator( $reg1, '2004' );
                        is_deeply( $ii, ['151'], 'valor de 2004 ativo' );
                        #$ii = &get_indicator( $reg1, '2004', 1 );
                        #is_deeply( $ii, [], 'nao existe valor active_value=0 para 2004' );
=cut

                        $ii = &get_indicator( $reg1, '2005' );
                        is_deeply( $ii, [ 1 + 80 + 82 ], 'valor de 2005 ativo eh a soma' );

                        $Iota::IndicatorData::DEBUG = 0;

                        #$ii = &get_indicator( $reg1, '2005', 1 );
                        #is_deeply( $ii, [], 'nao existe valor active_value=0 para 2005' );

                        $ii = &get_indicator( $reg1, '2006' );
                        is_deeply( $ii, [ 1 + 95 + 94 ], 'valor de 2006 ativo eh a soma' );

                        #$ii = &get_indicator( $reg1, '2006', 1 );
                        #is_deeply( $ii, [], 'nao existe valor active_value=0 para 2006' );

                        die 'undo-savepoint';
                    }
                );
                die $@ unless $@ =~ /undo-savepoint/;
            };

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;

sub update_region_valid_time {

    $schema->resultset('Region')->find(
        {
            id => shift->{id}
        }
      )->update(
        {
            subregions_valid_after => shift
        }
      );

}

sub update_region_valid_time_api {
    my ( $reg, $valid ) = @_;
    my ( $res, $c )     = ctx_request(
        POST $city_uri . '/region/' . $reg->{id},
        [
            api_key                                     => 'test',
            'city.region.update.subregions_valid_after' => $valid,
        ]
    );

    ok( $res->is_success, 'region updated!' );
}

sub add_value {
    my ( $region, $value, $year, $expcode ) = @_;

    $expcode ||= 201;

    note "POSTING $region/value\tyear $year, value $value";

    # PUT normal
    my $req = POST $region . '/value',
      [
        'region.variable.value.put.value'         => $value,
        'region.variable.value.put.variable_id'   => $variable->{id},
        'region.variable.value.put.value_of_date' => $year . '-01-01'
      ];
    $req->method('PUT');

    my ( $res, $c ) = ctx_request($req);

    #exit if $expcode == 404;
    ok( $res->is_success, 'variable value created' ) if $expcode == 201;
    is( $res->code, $expcode, 'response code is ' . $expcode );
    my $id = eval { from_json( $res->content ) };

    return $id;
}

sub get_values {
    my ( $region, $not ) = @_;

    $not = $not ? 0 : 1;
    my ( $res, $c ) =
      ctx_request( GET '/api/user/'
          . $Iota::TestOnly::Mock::AuthUser::_id
          . '/variable?region_id='
          . $region->{id}
          . '&is_basic=0&variable_id='
          . $variable->{id}
          . '&active_value='
          . $not );
    is( $res->code, 200, 'list the values exists -- 200 Success' );
    my $list = eval { from_json( $res->content ) };
    return $list->{variables}[0]{values};
}

sub get_indicator {
    my ( $region, $year, $not ) = @_;

    $not = $not ? 0 : 1;

    my ( $res, $c ) =
      ctx_request( GET '/api/public/user/'
          . $Iota::TestOnly::Mock::AuthUser::_id
          . '/indicator?from_date='
          . $year
          . '-01-01&number_of_periods=0&region_id='
          . $region->{id}
          . '&active_value='
          . $not );
    is( $res->code, 200, 'list the values exists -- 200 Success' );

    my $list = eval { from_json( $res->content ) };
    $list = &get_the_key( &get_the_key( &get_the_key($list) ) )->{indicadores}[0]{valores};

    return $list;
}

# see end() in php
sub get_the_key {
    my ($hash) = @_;
    my ($k)    = keys %$hash;
    return $hash->{$k};
}
