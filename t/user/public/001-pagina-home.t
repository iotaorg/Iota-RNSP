
use strict;
use warnings;

use JSON qw(from_json);
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Catalyst::Test q(Iota::PCS);

use HTTP::Request::Common qw /GET POST/;
use URI;
use Package::Stash;

use Iota::PCS::TestOnly::Mock::AuthUser;

my $schema = Iota::PCS->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::PCS::TestOnly::Mock::AuthUser->new;

$Iota::PCS::TestOnly::Mock::AuthUser::_id    = 2;
@Iota::PCS::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

eval {
    $schema->txn_do(
        sub {
            my ( $res, $c );


            my $city = $schema->resultset('City')->create(
                    {
                        uf   => 'XX',
                        name => 'AWS',
                        telefone_prefeitura => '12345555'
                    },
                );

            ( $res, $c ) = ctx_request(
                POST '/api/user',
                [
                api_key                        => 'test',
                'user.create.name'             => 'Foo Bar',
                'user.create.email'            => 'foo@email.com',
                'user.create.password'         => 'foobarquux1',
                'user.create.password_confirm' => 'foobarquux1',
                'user.create.city_id'          => $city->id,
                'user.create.role'             => 'user',
                'user.create.network_id'        => 1,
                'user.create.city_summary'     => 'testestes',
                'user.create.endereco'         => 'endereco_t'
                ]
            );
            ok( $res->is_success, 'user created' );
            is( $res->code, 201, 'user created' );
            ok(
                my $new_user =
                $schema->resultset('User')->find( { email => 'foo@email.com' } ),
                'user in DB'
            );
            is(eval{$new_user->network_id}, 1, 'criado como prefeito');



            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [   api_key                        => 'test',
                    'variable.create.name'         => 'Temperatura semanal',
                    'variable.create.cognomen'     => 'temp_semana',
                    'variable.create.period'       => 'weekly',
                    'variable.create.explanation'  => 'a foo with bar',
                    'variable.create.type'         => 'int',
                ]
            );
            ok( $res->is_success, 'variable created!' );
            my $uri = URI->new( $res->header('Location') . '/value' );
            my $var = eval{from_json( $res->content )};


            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [   api_key                        => 'test',
                    'variable.create.name'         => 'nostradamus',
                    'variable.create.cognomen'     => 'nostradamus',
                    'variable.create.period'       => 'weekly',
                    'variable.create.explanation'  => 'nostradamus end of world',
                    'variable.create.type'         => 'int',
                ]
            );
            ok( $res->is_success, 'variable created!' );
            my $uri2 = URI->new( $res->header('Location') . '/value' );
            my $var2 = eval{from_json( $res->content )};

            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [   api_key                        => 'test',
                    'variable.create.name'         => 'nostradamus 2',
                    'variable.create.cognomen'     => 'poxa_vida',
                    'variable.create.period'       => 'yearly',
                    'variable.create.explanation'  => 'nostradamus end of world',
                    'variable.create.type'         => 'num',
                ]
            );
            ok( $res->is_success, 'variable created!' );

            my $uri3 = URI->new( $res->header('Location') . '/value' );
            my $var3 = eval{from_json( $res->content )};

            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [   api_key                        => 'test',
                    'variable.create.name'         => 'nostradamus 3',
                    'variable.create.cognomen'     => 'poxa_vid2a',
                    'variable.create.period'       => 'yearly',
                    'variable.create.explanation'  => 'nostradamus end of world',
                    'variable.create.type'         => 'num',
                ]
            );
            ok( $res->is_success, 'variable created!' );

            my $uri4 = URI->new( $res->header('Location') . '/value' );
            my $var4 = eval{from_json( $res->content )};


            ( $res, $c ) = ctx_request(
                POST '/api/indicator',
                [   api_key                         => 'test',
                    'indicator.create.name'         => 'Temperatura maxima da semana: SP',
                    'indicator.create.formula'      => '$' . $var->{id} . '+ $' . $var2->{id},
                    'indicator.create.goal'         => '33',
                    'indicator.create.axis_id'      => '2',
                    'indicator.create.explanation'  => 'explanation',
                    'indicator.create.source'       => 'me',
                    'indicator.create.goal_source'  => '@fulano',
                    'indicator.create.chart_name'   => 'pie',
                    'indicator.create.goal_operator'=> '<=',
                    'indicator.create.tags'         => 'you,me,she',
                    'indicator.create.indicator_roles' => '_prefeitura,',

                ]
            );
            ok( $res->is_success, 'indicator created!' );
            my $uri_chart = URI->new( $res->header('Location') . '/variable/value' );
            my $indicator = eval{from_json( $res->content )};

            $Iota::PCS::TestOnly::Mock::AuthUser::_id = $new_user->id;

            my $variable_url = $uri->path_query;

            &add_value($variable_url, '2012-01-01', 23);
            &add_value($variable_url, '2012-01-08', 25);
            &add_value($variable_url, '2012-01-15', 26);
            &add_value($variable_url, '2012-01-26', 28);
            &add_value($variable_url, '2012-01-30', 29);


            $variable_url = $uri2->path_query;
            ## var 2
            &add_value($variable_url, '2012-01-01', 3);
            &add_value($variable_url, '2012-01-09', 5);
            &add_value($variable_url, '2012-01-17', 6);
            &add_value($variable_url, '2012-01-26', 8);
            &add_value($variable_url, '2012-01-30', 8);


            $Iota::PCS::TestOnly::Mock::AuthUser::_id = 1; # ADMIN
            ( $res, $c ) = ctx_request(
                POST '/api/indicator',
                [   api_key                         => 'test',
                    'indicator.create.name'         => 'outra coisa por ano: SP',
                    'indicator.create.formula'      => '$' . $var3->{id} ,
                    'indicator.create.goal'         => '33',
                    'indicator.create.axis_id'      => '2',
                    'indicator.create.explanation'  => 'explanation',
                    'indicator.create.source'       => 'me',
                    'indicator.create.goal_source'  => '@fulano',
                    'indicator.create.chart_name'   => 'pie',
                    'indicator.create.goal_operator'=> '<=',
                    'indicator.create.tags'         => 'you,me,she',
                    'indicator.create.indicator_roles' => '_prefeitura,',
                ]
            );
            ok( $res->is_success, 'indicator created!' );

            my $indicator2 = eval{from_json( $res->content )};

            ( $res, $c ) = ctx_request(
                POST '/api/indicator',
                [   api_key                         => 'test',
                    'indicator.create.name'         => '111: SP',
                    'indicator.create.formula'      => '$' . $var4->{id} ,
                    'indicator.create.goal'         => '33',
                    'indicator.create.axis_id'      => '2',
                    'indicator.create.explanation'  => 'explanation',
                    'indicator.create.source'       => 'me',
                    'indicator.create.goal_source'  => '@fulano',
                    'indicator.create.chart_name'   => 'pie',
                    'indicator.create.goal_operator'=> '<=',
                    'indicator.create.tags'         => 'you,me,she',
                    'indicator.create.indicator_roles' => '_prefeitura,',

                ]
            );
            ok( $res->is_success, 'indicator created!' );

            $uri = URI->new( $res->header('Location') );
            ( $res, $c ) = ctx_request(
                POST $uri->path . '/network_config/1',
                [   api_key                                     => 'test',
                    'indicator.network_config.upsert.unfolded_in_home' => 1,
                ]
            );

            my $indicator3 = eval{from_json( $res->content )};

            $Iota::PCS::TestOnly::Mock::AuthUser::_id = $new_user->id;

            $variable_url = $uri3->path_query;

            &add_value($variable_url, '2012-01-01', '23,5');
            &add_value($variable_url, '2011-01-08', '25,8');
            &add_value($variable_url, '2008-01-15', '26,8');
            &add_value($variable_url, '2010-01-26', '28,6');
            &add_value($variable_url, '1998-01-30', '29,588');


            $variable_url = $uri4->path_query;

            &add_value($variable_url, '2011-01-01', '222,5');
            &add_value($variable_url, '2010-01-08', '1 222 245,8');
            &add_value($variable_url, '2009-01-15', '11.246,8');
            &add_value($variable_url, '2008-01-26', '258');



            # variavel basicas
            my $basic_id = $schema->resultset('Variable')->search( { is_basic => 1 } )->next->id;

            &add_value('/api/variable/'.$basic_id.'/value', '2012-03-25', 15);
            &add_value('/api/variable/'.$basic_id.'/value', '1192-03-25', 5);
            &add_value('/api/variable/'.$basic_id.'/value', '1193-03-25', 6);
            &add_value('/api/variable/'.$basic_id.'/value', '1195-03-25', 7);


            ( $res, $c ) = ctx_request(GET '/api/public/user/'.$Iota::PCS::TestOnly::Mock::AuthUser::_id);
            my $obj = eval{from_json( $res->content )};

            ok($res->is_success, 'GET public info success');

            is($obj->{variaveis}[0]{last_value}, 15, 'ultimo valor ok');
            is($obj->{variaveis}[0]{period}, 'yearly', 'periodo das variaveis basicas nao mudaram');
            is($obj->{variaveis}[0]{last_value_date}, '2012-01-01', 'data do ultimo valor ok');


            is($obj->{cidade}{name}, 'AWS', 'cidade OK');
            is($obj->{usuario}{city_summary}, 'testestes', 'summary OK');

            SKIP: {
                skip 'Endereco do usuario esta confirmado se eh publico', 1;
                is($obj->{usuario}{telefone_prefeitura}, '12345555','telefone da cidade');
            };
            is($obj->{cidade}{name}, 'AWS', 'cidade OK');

            ( $res, $c ) = ctx_request(GET '/api/public/user/'.$Iota::PCS::TestOnly::Mock::AuthUser::_id . '/indicator');
            $obj = eval{from_json( $res->content )};

            is($obj->{resumos}{'Bens Naturais Comuns'}{weekly}{datas}[0]{data}, '2012-01-08', 'data da primeira semana ok');
            is(join(',', @{$obj->{resumos}{'Bens Naturais Comuns'}{weekly}{indicadores}[0]{valores}}), '30,32,36,37', 'valores da semana ok');

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;


sub add_value {
    my ($variable_url, $date, $value) = @_;

    my $req = POST $variable_url, [
        'variable.value.put.value'         => $value,
        'variable.value.put.value_of_date' => $date,
    ];
    $req->method('PUT');
    my ( $res, $c ) = ctx_request($req);
    ok( $res->is_success, 'value ' . $value .  ' on ' . $date . ' created!' );
    if (!$res->is_success){
        use DDP; p $res;
    }
    my $variable = eval{from_json( $res->content )};
    return $variable;

}