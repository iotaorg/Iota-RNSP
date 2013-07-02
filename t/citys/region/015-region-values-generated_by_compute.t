
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

            &add_value( $reg2_uri, '100', '2010' );
            my $tmp = &get_values($reg2);

            is( scalar keys @$tmp, '1', 'só tem 1 linha' );
            my $ii = &get_indicator( $reg2, '2010' );
            is_deeply( $ii, [101], 'valores salvos ok' );

            &add_value( $reg2_uri, '200', '2011' );
            $tmp = &get_values($reg2);
            is( scalar keys @$tmp, '2', 'tem 2 linhas' );
            $ii = &get_indicator( $reg2, '2011' );
            is_deeply( $ii, [201], 'valores salvos ok' );

            $tmp = &get_values($reg1);
            is( scalar keys @$tmp, '2', 'tem 2 linhas tambem na regiao 1' );

            $tmp = [ sort { $a->{valid_from} cmp $b->{valid_from} } @{$tmp} ];
            is( $tmp->[0]{value}, '100' );
            is( $tmp->[1]{value}, '200' );

            $ii = &get_indicator( $reg1, '2010' );
            is_deeply( $ii, [101], 'valores salvos ok' );

            $ii = &get_indicator( $reg1, '2011' );
            is_deeply( $ii, [201], 'valores salvos ok' );

            &add_value( $reg3_uri, '150,6668', '2010' );

            $ii = &get_indicator( $reg1, '2010' );
            is_deeply( $ii, ['251.6668'], 'valores salvos ok' );

            $tmp = &get_values($reg1);

            is( scalar keys @$tmp, '2', 'tem 2 linhas ainda, mas somados' );
            $tmp = [ sort { $a->{valid_from} cmp $b->{valid_from} } @{$tmp} ];
            is( $tmp->[0]{value}, '250.6668' );

            $tmp = &get_values( $reg1, 1 );
            is( scalar keys @$tmp, '0', 'tem 0 linhas ainda, pq nenhum user fez put nesses caras' );

            &add_value( $reg1_uri, '666', '2011' );
            $tmp = &get_values( $reg1, 1 );
            is( scalar keys @$tmp,       '1',   'tem 1 linha' );
            is( $tmp->[0]{value},        '666', 'valor salvo!' );
            is( $tmp->[0]{active_value}, '0',   'valor nao ativo' );

            $ii = &get_indicator( $reg1, '2010' );
            is_deeply( $ii, ['251.6668'], 'ainda existe esse valor!' );

            $ii = &get_indicator( $reg1, '2011', 1 );
            is_deeply( $ii, ['667'], 'e tem como pegar o valor nao computado' );

            $tmp = &get_values($reg1);
            is( scalar keys @$tmp, '2', 'tem 2 linhas ainda' );
            $tmp = [ sort { $a->{valid_from} cmp $b->{valid_from} } @{$tmp} ];
            is( $tmp->[0]{value},        '250.6668', 'valor ainda eh o mesmo!' );
            is( $tmp->[0]{active_value}, '1',        'valor ativo' );

            $ii = &get_indicator( $reg1, '2010' );
            is_deeply( $ii, ['251.6668'], 'ainda existe esse valor!' );

            &add_value( $reg1_uri, '444', '2010' );

            $ii = &get_indicator( $reg1, '2010', 1 );
            is_deeply( $ii, ['445'], 'existe o do usuario pra 2010' );

            &add_value( $reg2_uri, '22', '2010' );
            $tmp = &get_values($reg2);

            is( scalar keys @$tmp, '2', 'tem 2 linhas, uma de 2010 e outra de 2011' );
            $ii = &get_indicator( $reg2, '2010' );
            is_deeply( $ii, [23], 'valores atualizado' );

            $ii = &get_indicator( $reg1, '2010' );
            is_deeply( $ii, ['173.6668'], 'valores atualizado' );

            $ii = &get_indicator( $reg1, '2010', 1 );
            is_deeply( $ii, ['445'], 'ainda existe o do usuario' );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;

sub add_value {
    my ( $region, $value, $year ) = @_;

    # PUT normal
    my $req = POST $region . '/value',
      [
        'region.variable.value.put.value'         => $value,
        'region.variable.value.put.variable_id'   => $variable->{id},
        'region.variable.value.put.value_of_date' => $year . '-01-01'
      ];
    $req->method('PUT');
    my ( $res, $c ) = ctx_request($req);

    ok( $res->is_success, 'variable value created' );
    is( $res->code, 201, 'value added -- 201 ' );
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
          . '-01-01&number_of_periods=1&region_id='
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
