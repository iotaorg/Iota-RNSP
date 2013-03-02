
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";


use JSON qw(from_json);
use Catalyst::Test q(RNSP::PCS);

use HTTP::Request::Common qw(GET POST DELETE PUT);

use Package::Stash;

use RNSP::PCS::TestOnly::Mock::AuthUser;

my $schema = RNSP::PCS->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = RNSP::PCS::TestOnly::Mock::AuthUser->new;

my $uid = $RNSP::PCS::TestOnly::Mock::AuthUser::_id    = 1;
@RNSP::PCS::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );
my $seq = 0;
eval {
    $schema->txn_do(
        sub {
            my ( $res, $c );
            ( $res, $c ) = ctx_request(
                POST '/api/indicator',
                [   api_key                   => 'test',
                    'indicator.create.name'   => 'FooBar',
                ]
            );
            ok( !$res->is_success, 'invalid request' );
            is( $res->code, 400, 'invalid request' );

            my $var1 = &new_var('int', 'weekly');

            ( $res, $c ) = ctx_request(
                POST '/api/indicator',
                [   api_key                         => 'test',
                    'indicator.create.name'         => 'Foo Bar',
                    'indicator.create.formula'      => '5 + $' . $var1,
                    'indicator.create.axis_id'      => '1',
                    'indicator.create.explanation'  => 'explanation',
                    'indicator.create.source'       => 'me',
                    'indicator.create.goal_source'  => '@fulano',
                    'indicator.create.chart_name'   => 'pie',
                    'indicator.create.goal_operator'=> '>=',
                    'indicator.create.tags'         => 'you,me,she',
                    'indicator.create.observations' => 'lala',
                    'indicator.create.indicator_roles' => '_prefeitura,_movimento'

                ]
            );
            ok( $res->is_success, 'indicator created!' );
            is( $res->code, 201, 'created!' );
            my $ind = eval{from_json($res->content)};

            ( $res, $c ) = ctx_request(
                POST "/api/user/$uid/indicator",
                [   api_key                         => 'test',
                    'user.indicator.create.goal'         => 'bass down low',
                    'user.indicator.create.indicator_id' => $ind->{id},
                    'user.indicator.create.valid_from'   => '2012-11-21'
                ]
            );
            use URI;
            my $uri = URI->new( $res->header('Location') );

            ( $res, $c ) = ctx_request( GET $uri->path_query );
            is( $res->code, 200, 'GET OK!!' );

            my $dados = eval{from_json( $res->content )};

            is($dados->{goal}, 'bass down low', 'goal ok');
            is($dados->{valid_from}, '2012-11-18', 'start week ok');
            is($dados->{valid_from}, '2012-11-18', 'start week ok');
            is($dados->{indicator_id}, $ind->{id}, 'indicator ok');
            is($dados->{justification_of_missing_field}||'', '', 'empty justification_of_missing_field');


            ( $res, $c ) = ctx_request(
                POST $uri->path_query,
                [   api_key                         => 'test',
                    'user.indicator.update.justification_of_missing_field' => 'escape'
                ]
            );
            is( $res->code, 202, 'Updated OK!!' );

            ( $res, $c ) = ctx_request( GET $uri->path_query );
            is( $res->code, 200, 'GET OK!!' );

            $dados = eval{from_json( $res->content )};
            is($dados->{justification_of_missing_field}, 'escape', 'justification ok');


            # ok nova data
            ( $res, $c ) = ctx_request(
                POST "/api/user/$uid/indicator",
                [   api_key                         => 'test',
                    'user.indicator.create.goal'         => 'bass down low',
                    'user.indicator.create.indicator_id' => $ind->{id},
                    'user.indicator.create.valid_from'   => '2012-11-25'
                ]
            );
            is( $res->code, 201, 'created com nova data!' );

            # apagar
            ( $res, $c ) = ctx_request(
                DELETE $uri->path_query
            );
            is( $res->code, 204, '204 / no content!!' );

            ( $res, $c ) = ctx_request(
                DELETE $uri->path_query
            );
            is( $res->code, 404, '404 / not found!!' );

            # data duplicada
            ( $res, $c ) = ctx_request(
                POST "/api/user/$uid/indicator",
                [   api_key                         => 'test',
                    'user.indicator.create.goal'         => 'my world ft giovanca',
                    'user.indicator.create.indicator_id' => $ind->{id},
                    'user.indicator.create.valid_from'   => '2012-11-26'
                ]
            );

            is( $res->code, 400, '400 bad request!!' );
            $dados = eval{from_json( $res->content )};

            # TODO garibuh, esqueci de perguntar... mas porque usar um JSON dentro do json?!
            is($dados->{error},'{"user.indicator.create.valid_from.invalid":1}', 'campo valid_from invalido');

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;

sub new_var {
    my $type = shift;
    my $period = shift;
    my ( $res, $c ) = ctx_request(
        POST '/api/variable',
        [   api_key                        => 'test',
            'variable.create.name'         => 'Foo Bar'.$seq++,
            'variable.create.cognomen'     => 'foobar'.$seq++,
            'variable.create.explanation'  => 'a foo with bar'.$seq++,
            'variable.create.type'         => $type,
            'variable.create.period'       => $period||'weekly',
            'variable.create.source'       => 'God',
        ]
    );
    if ($res->code == 201){
        my $xx = eval{from_json( $res->content )};
        return $xx->{id};
    }else{
        die('fail to create new var: ' . $res->code);
    }
}

