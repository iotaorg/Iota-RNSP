
use strict;
use warnings;

use JSON qw(from_json);
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Catalyst::Test q(RNSP::PCS);

use HTTP::Request::Common qw /GET POST/;
use URI;
use Package::Stash;

use RNSP::PCS::TestOnly::Mock::AuthUser;

my $schema = RNSP::PCS->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = RNSP::PCS::TestOnly::Mock::AuthUser->new;

$RNSP::PCS::TestOnly::Mock::AuthUser::_id    = 1;
@RNSP::PCS::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

use DateTime;
sub get_week {
    return DateTime->now->add( {weeks => shift, days => -1 } )->ymd; # tem q tirar 1 dia pra voltar a ser domingo!
}

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
                'user.create.prefeito'         => 1,
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
            is(eval{$new_user->prefeito->user_id}, $new_user->id, 'criado como prefeito');



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

                ]
            );
            ok( $res->is_success, 'indicator created!' );
            my $uri_chart = URI->new( $res->header('Location') . '/variable/value' );
            my $indicator = eval{from_json( $res->content )};

            $RNSP::PCS::TestOnly::Mock::AuthUser::_id = $new_user->prefeito->user_id;

            ( $res, $c ) = ctx_request(GET '/api/public/user/'.$RNSP::PCS::TestOnly::Mock::AuthUser::_id.'/indicator/status');
            ok($res->is_success, 'GET public info success');
            my $obj = eval{from_json( $res->content )};

            is_deeply($obj, {
                status => [
                    {
                        completo_historico=>  0,
                        id                =>  $indicator->{id},
                        outros_periodos   =>  0,
                        ultimo_periodo    =>  0
                    }
                ]
            }, 'teste condicao 1');


            my $variable_url = $uri->path_query;

            &add_value($variable_url, get_week(-4), 23);
            $variable_url = $uri2->path_query;
            &add_value($variable_url, get_week(-4), 3);

            ( $res, $c ) = ctx_request(GET '/api/public/user/'.$RNSP::PCS::TestOnly::Mock::AuthUser::_id.'/indicator/status');
            ok($res->is_success, 'GET public info success');
            $obj = eval{from_json( $res->content )};

            is_deeply($obj, {
                status => [
                    {
                        completo_historico=>  0,
                        id                =>  $indicator->{id},
                        outros_periodos   =>  1,
                        ultimo_periodo    =>  0
                    }
                ]
            }, 'teste condicao 2');

            $variable_url = $uri->path_query;
            &add_value($variable_url, get_week(-1), 1);
            $variable_url = $uri2->path_query;
            &add_value($variable_url, get_week(-1), 1);

            ( $res, $c ) = ctx_request(GET '/api/public/user/'.$RNSP::PCS::TestOnly::Mock::AuthUser::_id.'/indicator/status');
            ok($res->is_success, 'GET public info success');
            $obj = eval{from_json( $res->content )};

            is_deeply($obj, {
                status => [
                    {
                        completo_historico=>  0,
                        id                =>  $indicator->{id},
                        outros_periodos   =>  1,
                        ultimo_periodo    =>  1
                    }
                ]
            }, 'teste condicao 3');

            $variable_url = $uri->path_query;
            &add_value($variable_url, get_week(-3), 1);

            &add_value($variable_url, get_week(-2), 2);
            $variable_url = $uri2->path_query;

            &add_value($variable_url, get_week(-3), 1);

            &add_value($variable_url, get_week(-2), 3);


            ( $res, $c ) = ctx_request(GET '/api/public/user/'.$RNSP::PCS::TestOnly::Mock::AuthUser::_id.'/indicator/status');
            ok($res->is_success, 'GET public info success');
            $obj = eval{from_json( $res->content )};

            is_deeply($obj, {
                status => [
                    {
                        completo_historico=>  1,
                        id                =>  $indicator->{id},
                        outros_periodos   =>  1,
                        ultimo_periodo    =>  1
                    }
                ]
            }, 'teste condicao 4');


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