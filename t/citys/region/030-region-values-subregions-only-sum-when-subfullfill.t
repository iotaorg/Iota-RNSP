use Test::More;

use strict;
use warnings;
use URI;
use Test::More;
use JSON qw(from_json);

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

=pod
            my $inst = $schema->resultset('Institute')->create(
                {
                    active_me_when_empty => 1,
                    name => 'name',
                    short_name => 'short_name',

                }
            );
            my $net = $schema->resultset('Network')->create(
                {
                    name => 'name',
                    name_url => 'short_name',
                    domain_name => 'domain_name',
                    created_by => 1,
                    institute_id => $inst->id,
                }
            );

            my $u = $schema->resultset('User')->create(
                {
                    name => 'name',
                    email => 'email@email.com',
                    institute_id => $inst->id,
                    password => '!!!',
                    regions_enabled => 1
                }
            );
            $u->add_to_user_roles( { role => { name => 'admin' } } );
            $u->add_to_network_users( { network_id => $net->id } );

            $ENV{HARNESS_ACTIVE_institute_id} = $inst->id;

            $Iota::TestOnly::Mock::AuthUser::_id    = $u->id;
=cut

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

            # cria regiao
            $city_uri = $res->header('Location');
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

            ( $res, $c ) = ctx_request(
                POST $city_uri . '/region',
                [
                    api_key                           => 'test',
                    'city.region.create.name'         => 'subregion b',
                    'city.region.create.upper_region' => $region->{id},
                    'city.region.create.description'  => 'with Descriptionx',
                ]
            );

            ok( $res->is_success, 'region created!' );
            is( $res->code, 201, 'region created!' );

            my $subregion2_uri = $res->header('Location');
            ( $res, $c ) = ctx_request( GET $subregion2_uri );
            my $subregion2 = eval { from_json( $res->content ) };
            ( $subregion2->{id} ) = $subregion2_uri =~ /\/([0-9]+)$/;

            ( $res, $c ) = ctx_request(
                POST $city_uri . '/region',
                [
                    api_key                           => 'test',
                    'city.region.create.name'         => 'subregion c',
                    'city.region.create.upper_region' => $region->{id},
                    'city.region.create.description'  => 'with Descriptionx',
                ]
            );

            ok( $res->is_success, 'region created!' );
            is( $res->code, 201, 'region created!' );

            my $subregion3_uri = $res->header('Location');
            ( $res, $c ) = ctx_request( GET $subregion3_uri );
            my $subregion3 = eval { from_json( $res->content ) };
            ( $subregion3->{id} ) = $subregion3_uri =~ /\/([0-9]+)$/;

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

                        #$ii = &get_indicator( $region, '2002', 1 );
                        #is_deeply( $ii, [], 'nao existe valor active_value=0 para 2002' );

                        $ii = &get_indicator( $region, '2003' );
                        is_deeply( $ii, ['361'], 'valor de 2003 ativo' );

                        #$ii = &get_indicator( $region, '2003', 1 );
                        #is_deeply( $ii, [], 'nao existe valor active_value=0 para 2003' );

                        $ii = &get_indicator( $region, '2004' );
                        is_deeply( $ii, ['451'], 'valor de 2004 ativo' );

                        #$ii = &get_indicator( $region, '2004', 1 );
                        #is_deeply( $ii, [], 'nao existe valor active_value=0 para 2004' );

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

                        #$ii = &get_indicator( $region, '2005', 1 );
                        #is_deeply( $ii, [ 1 + 55 + 666 ], 'nao existe valor active_value=0 para 2005 eh a soma' );

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

                        #$ii = &get_indicator( $region, '2005', 1 );

                        #is_deeply( $ii, [ 1 + 55 + 666 ], 'valor active_value=0 para 2005 tabem existe' );

                        note('sit 3: Nível superior preenchido, com dados incompletos no nível inferior');
                        $current_var = $variable->{id};
                        &add_value( $subregion2_uri, '10', '2005' );
                        &add_value( $subregion3_uri, '10', '2005' );

                        $current_var = $variable2->{id};
                        &add_value( $subregion1_uri, '33', '2005' );

                        &add_value( $subregion2_uri, '34', '2005' );

                        $ii = &get_indicator( $region, '2005' );
                        is_deeply( $ii, [ 1 + 55 + 666 ], 'valor de 2005 ativo ainda eh da regiao 2 apenas' );

                        #$ii = &get_indicator( $region, '2005', 1 );
                        #is_deeply( $ii, [ 1 + 55 + 666 ], 'valor active_value=0 para 2005 tabem existe' );

                        $current_var = $variable->{id};
                        &add_value( $subregion1_uri, '10', '2005' );

                        $ii = &get_indicator( $region, '2005' );
                        is_deeply(
                            $ii,
                            [ 1 + 30 + 666 ],
'valor de 2005 ativo agora esta usando um pouco de cada (30 eh a soma da vriavel 1) e a 666 da variavel 2'
                        );

                        #$ii = &get_indicator( $region, '2005', 1 );
                        #is_deeply( $ii, [ 1 + 55 + 666 ], 'valor active_value=0 para 2005 tabem existe' );

                        note('sit 4: Nível superior preenchido, com dados completos no nível inferior');

                        $current_var = $variable2->{id};

                        # isso fecha a conta
                        &add_value( $subregion3_uri, '35', '2005' );

                        $ii = &get_indicator( $region, '2005' );
                        is_deeply(
                            $ii,
                            [ 1 + ( 10 + 33 ) + ( 10 + 34 ) + ( 10 + 35 ) ],
                            'valor de 2005 ativo agora eh a soma das 3 subs.'
                        );

                        #$ii = &get_indicator( $region, '2005', 1 );
                        #is_deeply( $ii, [ 1 + 55 + 666 ], 'valor active_value=0 para 2005 eh o da cidade.' );

                        note('sit 5: Nível inferior preenchido completamente, sem dados no nível superior');

                        $current_var = $variable->{id};
                        &add_value( $subregion1_uri, '8',  '2008' );
                        &add_value( $subregion2_uri, '16', '2008' );
                        &add_value( $subregion3_uri, '32', '2008' );

                        $current_var = $variable2->{id};
                        &add_value( $subregion1_uri, '33', '2008' );
                        &add_value( $subregion2_uri, '34', '2008' );
                        &add_value( $subregion3_uri, '36', '2008' );

                        $ii = &get_indicator( $region, '2008' );
                        is_deeply(
                            $ii,
                            [ 1 + ( 8 + 33 ) + ( 16 + 34 ) + ( 32 + 36 ) ],
                            'valor de 2008 ativo agora eh a soma das 3 subs.'
                        );

                        #$ii = &get_indicator( $region, '2008', 1 );
                        #is_deeply( $ii, [], 'nao existe valor active_value=0 para 2008' );

                        note('sit 6: Nível inferior incompleto, sem dados no nível superior');

                        $current_var = $variable->{id};
                        &add_value( $subregion1_uri, '8',  '2009' );
                        &add_value( $subregion3_uri, '32', '2009' );

                        $current_var = $variable2->{id};
                        &add_value( $subregion1_uri, '33', '2009' );
                        &add_value( $subregion2_uri, '34', '2009' );
                        &add_value( $subregion3_uri, '36', '2009' );

                        $ii = &get_indicator( $region, '2009' );
                        is_deeply( $ii, [], 'sem valor ativo para 2009' );

                        $ii = &get_indicator( $region, '2009', 1 );
                        is_deeply( $ii, [], 'nao existe valor active_value=0 para 2009' );

                        note('sit 7: valor incompleto abaixo, e depois mudou o valor de cima');

                        $current_var = $variable->{id};
                        &add_value( $subregion1_uri, '8', '2066' );

                        $current_var = $variable2->{id};
                        &add_value( $subregion1_uri, '12', '2066' );

                        $current_var = $variable->{id};
                        &add_value( $region_uri, '888', '2066' );

                        $current_var = $variable2->{id};
                        my $reg_id2 = &add_value( $region_uri, '999', '2066' );

                        # bom!
                        $ii = &get_indicator( $region, '2066' );
                        is_deeply( $ii, [ 1 + 888 + 999 ], 'valor ativo para 2066 eh o inputado.' );

                        #$ii = &get_indicator( $region, '2066', 1 );
                        #is_deeply( $ii, [ 1 + 888 + 999 ], 'valor inativo pra 2066 tambem eh o inputado.' );

                        # agora bora por tudo nas sub-regioes.
                        $current_var = $variable->{id};
                        &add_value( $subregion2_uri, '8', '2066' );
                        my $val_id1 = &add_value( $subregion3_uri, '8', '2066' );

                        $current_var = $variable2->{id};
                        &add_value( $subregion2_uri, '8', '2066' );
                        my $val_id2 = &add_value( $subregion3_uri, '55', '2066' );

                        $ii = &get_indicator( $region, '2066' );
                        is_deeply( $ii, [ 1 + 8 + 12 + 8 + 8 + 8 + 55 ], 'valor ativo para 2066 eh a soma.' );

                        #$ii = &get_indicator( $region, '2066', 1 );
                        #is_deeply( $ii, [ 1 + 888 + 999 ], 'valor inativo pra 2066 eh o da macro' );

                        # removendo agora um valor da sub.

                        ( $res, $c ) = ctx_request( DELETE $subregion3_uri. '/value/' . $val_id2->{id} );
                        is( $res->code, 204, 'response code is ' . 204 );

                        # virou intermediario.
                        $ii = &get_indicator( $region, '2066' );
                        is_deeply(
                            $ii,
                            [ 1 + 999 + 24 ],
'virou intermediario, que signfica, uma variavel vai vir da regiao, e a segunda da soma das 3 abaixo.'
                        );

                        ( $res, $c ) = ctx_request( DELETE $subregion3_uri. '/value/' . $val_id1->{id} );
                        is( $res->code, 204, 'response code is ' . 204 );

                        # voltou a ser o macro.
                        $ii = &get_indicator( $region, '2066' );
                        is_deeply( $ii, [ 1 + 888 + 999 ], 'voltou a ser macro' );

                        $Iota::IndicatorData::DEBUG = 0;

                        # apaga a da regiao.
                        ( $res, $c ) = ctx_request( DELETE $region_uri. '/value/' . $reg_id2->{id} );
                        is( $res->code, 204, 'response code is ' . 204 );

                        # em branco.
                        $ii = &get_indicator( $region, '2066' );
                        is_deeply( $ii, [], 'nao tem mais..' );

                        #$ii = &get_indicator( $region, '2066', 1 );
                        #is_deeply( $ii, [], 'nao tem mais..' );

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

