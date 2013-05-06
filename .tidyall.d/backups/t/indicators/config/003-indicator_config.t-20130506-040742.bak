
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Catalyst::Test q(Iota);

use HTTP::Request::Common qw(GET POST DELETE PUT);
use Package::Stash;

use Iota::TestOnly::Mock::AuthUser;

my $schema = Iota->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::TestOnly::Mock::AuthUser->new;

$Iota::TestOnly::Mock::AuthUser::_id    = 1;
use JSON qw(from_json);
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin user/;

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


            ( $res, $c ) = ctx_request(
                POST '/api/indicator',
                [   api_key                         => 'test',
                    'indicator.create.name'         => 'Foo Bar',
                    'indicator.create.formula'      => '5',
                    'indicator.create.axis_id'      => '1',
                    'indicator.create.explanation'  => 'explanation',
                    'indicator.create.source'       => 'me',
                    'indicator.create.goal_source'  => '@fulano',
                    'indicator.create.visibility_level' => 'public',
                    'indicator.create.chart_name'   => 'pie',
                    'indicator.create.goal_operator'=> '>=',
                    'indicator.create.tags'         => 'you,me,she',

                    'indicator.create.observations' => 'lala'

                ]
            );
            ok( $res->is_success, 'indicator created!' );
            is( $res->code, 201, 'created!' );

            my $indicator = eval{from_json( $res->content )};

            my $url_user = '/api/user/' .
                $Iota::TestOnly::Mock::AuthUser::_id . '/indicator_config';

            ( $res, $c ) = ctx_request(
                POST $url_user,
                [   api_key                         => 'test',
                    'user.indicator_config.create.indicator_id' => $indicator->{id},
                    'user.indicator_config.create.technical_information' => 'DetalheFoo',
                ]
            );
            ok( $res->is_success, 'indicator created!' );
            is( $res->code, 201, 'created!' );

            my $config_id = eval{from_json( $res->content )};

            ( $res, $c ) = ctx_request(
                POST $url_user,
                [   api_key                         => 'test',
                    'user.indicator_config.create.indicator_id' => $indicator->{id},
                    'user.indicator_config.create.technical_information' => 'DetalheFoo',
                ]
            );
            ok( !$res->is_success, '2 conf indicator not created!' );
            is( $res->code, 400, 'not created!' );
            like($res->content, qr|indicator_id\.invalid|, 'invalid');


            ( $res, $c ) = ctx_request(
                GET $url_user . '/' . $config_id->{id}
            );
            ok( $res->is_success, 'indicator get!' );
            is( $res->code, 200, 'created!' );

            my $config = eval{from_json( $res->content )};
            is($config->{technical_information}, 'DetalheFoo', 'technical_information: ok');


            ( $res, $c ) = ctx_request(
                POST $url_user . '/' . $config_id->{id},
                [   api_key                         => 'test',
                    'user.indicator_config.update.technical_information' => 'foobar',
                ]
            );
            ok( $res->is_success, 'indicator updated!' );
            is( $res->code, 202, 'updated!' );


            ( $res, $c ) = ctx_request(
                GET $url_user . '/' . $config_id->{id}
            );
            $config = eval{from_json( $res->content )};
            is($config->{technical_information}, 'foobar', 'technical_information: ok');

            ( $res, $c ) = ctx_request(
                GET $url_user . '?indicator_id=' . $indicator->{id}
            );
            my $config2 = eval{from_json( $res->content )};
            is($config2->{id}, $config_id->{id}, 'pesquisa funcionando');

            ( $res, $c ) = ctx_request(
                DELETE $url_user . '/' . $config_id->{id}
            );
            ok( $res->is_success, 'indicator deleted!' );
            is( $res->code, 204, 'deleted!' );


            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
