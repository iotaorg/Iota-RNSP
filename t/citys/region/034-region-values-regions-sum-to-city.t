use Test::More;

use strict;
use warnings;
use URI;
use Test::More;
use JSON qw(from_json);

use utf8;
use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Catalyst::Test q(Iota);

my $variable;
my $variable2;
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
my $current_var;
eval {
    $schema->txn_do(
        sub {

            my ( $res, $c );

            # cria cidade
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

            # cria regiao
            ( $res, $c ) = ctx_request(
                POST $city_uri . '/region',
                [
                    api_key                                     => 'test',
                    'city.region.create.name'                   => 'a city region',
                    'city.region.create.description'            => 'I am a city!',
                    'city.region.create.subregions_valid_after' => '1800-01-01',
                ]
            );

            ok( $res->is_success, 'region [as city] created!' );
            is( $res->code, 201, 'region [as city] created!' );

            my $upper_uri = $res->header('Location');
            my $upper = eval { from_json( $res->content ) };

            # cria regiao
            ( $res, $c ) = ctx_request(
                POST $city_uri . '/region',
                [
                    api_key                                     => 'test',
                    'city.region.create.name'                   => 'a region',
                    'city.region.create.description'            => 'with no description',
                    'city.region.create.subregions_valid_after' => '2005-01-01',
                ]
            );

            ok( $res->is_success, 'region created!' );
            is( $res->code, 201, 'region created!' );

            my $region_uri = $res->header('Location');
            my $region = eval { from_json( $res->content ) };

            $schema->resultset('Region')->search( { id => $upper->{id} } )->update( { depth_level => 1 } );

            $schema->resultset('Region')->search( { id => $region->{id} } )->update( { upper_region => $upper->{id} } );

            # hora das subregioes
            ( $res, $c ) = ctx_request(
                POST $city_uri . '/region',
                [
                    api_key                           => 'test',
                    'city.region.create.name'         => 'subregion a',
                    'city.region.create.upper_region' => $region->{id},
                    'city.region.create.description'  => 'with Description',
                ]
            );

            ok( $res->is_success, 'region created!' );
            is( $res->code, 201, 'region created!' );

            my $subregion1_uri = $res->header('Location');
            ( $res, $c ) = ctx_request( GET $subregion1_uri );
            my $subregion1 = eval { from_json( $res->content ) };
            ( $subregion1->{id} ) = $subregion1_uri =~ /\/([0-9]+)$/;

            # todas subregioes criadas.

            # criando 2 variaveis
            ( $res, $c ) = ctx_request( GET $region_uri );
            my $obj = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [
                    api_key                       => 'test',
                    'variable.create.name'        => 'Foo A',
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
                POST '/api/variable',
                [
                    api_key                       => 'test',
                    'variable.create.name'        => 'Foo B',
                    'variable.create.cognomen'    => 'foobar2',
                    'variable.create.period'      => 'yearly',
                    'variable.create.explanation' => 'a foo with bar 2',
                    'variable.create.type'        => 'num',
                ]
            );
            ok( $res->is_success, 'variable created!' );
            is( $res->code, 201, 'created!' );

            $variable2 = eval { from_json( $res->content ) };

            # cria indicador usando as duas variaveis
            ( $res, $c ) = ctx_request(
                POST '/api/indicator',
                [
                    api_key                          => 'test',
                    'indicator.create.name'          => 'Foo Bar',
                    'indicator.create.formula'       => '1 + $' . $variable->{id} . ' + $' . $variable2->{id},
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
                        $current_var = $variable->{id};
                        &add_value( $region_uri, '100', '2002' );
                        &add_value( $region_uri, '130', '2003' );
                        &add_value( $region_uri, '150', '2004' );

                        $current_var = $variable2->{id};
                        &add_value( $region_uri, '200', '2002' );
                        &add_value( $region_uri, '230', '2003' );
                        &add_value( $region_uri, '300', '2004' );

                        $ii = &get_indicator( $region, '2002' );
                        is_deeply( $ii, ['301'], 'valor de 2002 ativo' );

                        $ii = &get_indicator( $region, '2003' );
                        is_deeply( $ii, ['361'], 'valor de 2003 ativo' );

                        $ii = &get_indicator( $region, '2004' );
                        is_deeply( $ii, ['451'], 'valor de 2004 ativo' );

                        # verificado tudo antes de inserir os
                        # valores para 2005+

                        # sit 2:
                        note('Nível superior preenchido, sem dados no nível inferior');

                        $current_var = $variable->{id};
                        &add_value( $region_uri, '55', '2005' );

                        $current_var = $variable2->{id};
                        &add_value( $region_uri, '666', '2005' );

                        # como nao foi dito nada, a soma esta apenas no false.

                        $ii = &get_indicator( $region, '2005' );
                        is_deeply( $ii, [], 'valor de 2005 ativo nao existe' );

                        $Iota::TestOnly::Mock::AuthUser::_id    = 1;
                        @Iota::TestOnly::Mock::AuthUser::_roles = qw/ superadmin /;

                        # agora atualiza pra se nao exitir soma,
                        # usar o valor da cidade.
                        ( $res, $c ) = ctx_request(
                            POST '/api/institute/1',    # user_id=2 eh institute=1
                            [
                                'institute.update.active_me_when_empty' => '1',

                                # aproveita pra ligar a soma apenas se verdadeiro.
                                'institute.update.aggregate_only_if_full' => '1',
                            ]
                        );
                        ok( $res->is_success, 'institute updated' );
                        is( $res->code, 202, 'institute updated -- 202 Accepted' );

                        $Iota::TestOnly::Mock::AuthUser::_id    = 2;
                        @Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

                        $ii = &get_indicator( $region, '2005' );
                        is_deeply( $ii, [ 1 + 55 + 666 ], 'valor de 2005 ativo agora existe' );

                        note('sit 3: Nível superior preenchido, com dados incompletos no nível inferior');

                        $current_var = $variable2->{id};
                        &add_value( $subregion1_uri, '33', '2005' );

                        $ii = &get_indicator( $region, '2005' );
                        is_deeply( $ii, [ 1 + 55 + 33 ], 'valor de 2005 ativo ainda eh da regiao 2 apenas' );

                        $current_var = $variable->{id};
                        &add_value( $subregion1_uri, '10', '2005' );

                        $ii = &get_indicator( $region, '2005' );
                        is_deeply(
                            $ii,
                            [ 1 + 10 + 33 ],
'valor de 2005 ativo agora esta usando um pouco de cada (10 eh a soma da vriavel 1) e a 33 da variavel 2'
                        );

                        note('sit 4: Nível superior preenchido, com dados completos no nível inferior');

                        $ii = &get_indicator( $region, '2005' );
                        is_deeply( $ii, [ 1 + ( 10 + 33 ) ], 'valor de 2005 ativo agora eh a soma das 3 subs.' );

                        note('sit 5: Nível inferior preenchido completamente, sem dados no nível superior');

                        $current_var = $variable->{id};
                        &add_value( $subregion1_uri, '8', '2008' );

                        $current_var = $variable2->{id};
                        &add_value( $subregion1_uri, '33', '2008' );

                        $ii = &get_indicator( $region, '2008' );
                        is_deeply( $ii, [ 1 + ( 8 + 33 ) ], 'valor de 2008 ativo agora eh a soma das 3 subs.' );
                        $ii = &get_indicator( $upper, '2008' );
                        is_deeply( $ii, [ 1 + 8 + 33 ], 'city: valor de 2008 ativo agora eh a soma das 3 subs' );

                        note('sit 7: valor incompleto abaixo, e depois mudou o valor de cima');

                        $current_var = $variable->{id};
                        &add_value( $upper_uri, '220', '2066' );

                        $current_var = $variable->{id};
                        &add_value( $region_uri, '888', '2066' );

                        $current_var = $variable2->{id};
                        my $reg_id2 = &add_value( $region_uri, '999', '2066' );

                        # bom! pois 888 eh oq estava falso junto com 999
                        $ii = &get_indicator( $region, '2066' );
                        is_deeply( $ii, [ 1 + 888 + 999 ], 'valor ativo para 2066 eh o inputado.' );

                        $current_var = $variable->{id};
                        &add_value( $subregion1_uri, '8', '2066' );

                        # 8 = soma das regioes, 999 =  inputado em cima.
                        $ii = &get_indicator( $upper, '2066' );
                        is_deeply( $ii, [ 1 + 8 + 999 ], 'city: valor ativo para 2066 eh o inputado.' );

                        $current_var = $variable2->{id};
                        &add_value( $subregion1_uri, '12', '2066' );

                        $ii = &get_indicator( $region, '2066' );
                        is_deeply( $ii, [ 1 + 8 + 12 ], 'valor ativo para 2066 eh a soma.' );

                        $ii = &get_indicator( $upper, '2066' );
                        is_deeply( $ii, [ 1 + 8 + 12 ], 'city: valor ativo para 2066 tbm eh a soma.' );

                        $current_var = $variable2->{id};
                        &add_value( $upper_uri, '2000', '2066' );

                        $ii = &get_indicator( $upper, '2066' );
                        is_deeply( $ii, [ 1 + 8 + 12 ], 'city: valor se manteve.' );

                        $current_var = $variable2->{id};
                        &add_value( $upper_uri, '2000', '2066' );

                        $ii = &get_indicator( $upper, '2066' );
                        is_deeply( $ii, [ 1 + 8 + 12 ], 'city: valor se manteve.' );

                        $current_var = $variable->{id};
                        &add_value( $upper_uri, '2000', '2066' );

                        $ii = &get_indicator( $upper, '2066' );
                        is_deeply( $ii, [ 1 + 8 + 12 ], 'city: valor se manteve.' );

                        $current_var = $variable->{id};
                        &add_value( $upper_uri, '2000', '2055' );

                        $current_var = $variable2->{id};
                        &add_value( $upper_uri, '1500', '2055' );

                        $ii = &get_indicator( $upper, '2055' );
                        is_deeply( $ii, [ 1 + 2000 + 1500 ], 'city: valor da cidade eh o imputado.' );

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

sub add_value {
    my ( $region, $value, $year, $expcode ) = @_;

    $value =~ s/,/./;

    $expcode ||= 201;

    note "POSTING $region/value\tyear $year, value $value";

    # PUT normal
    my $req = POST $region . '/value',
      [
        'region.variable.value.put.value'         => $value,
        'region.variable.value.put.variable_id'   => $current_var,
        'region.variable.value.put.value_of_date' => $year . '-01-01'
      ];
    $req->method('PUT');
    my ( $res, $c ) = ctx_request($req);

    use Data::Dumper;
    print Dumper $res;
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

