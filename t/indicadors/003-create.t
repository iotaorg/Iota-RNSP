
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(RNSP::PCS);

use HTTP::Request::Common;
use Package::Stash;

use RNSP::PCS::TestOnly::Mock::AuthUser;

my $schema = RNSP::PCS->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = RNSP::PCS::TestOnly::Mock::AuthUser->new;

$RNSP::PCS::TestOnly::Mock::AuthUser::_id    = 1;
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
                    'indicator.create.goal'         => '33',
                    'indicator.create.axis_id'      => '1',
                    'indicator.create.explanation'  => 'explanation',
                    'indicator.create.source'       => 'me',
                    'indicator.create.goal_source'  => '@fulano',
                    'indicator.create.chart_name'   => 'pie',
                    'indicator.create.goal_operator'=> '>=',
                    'indicator.create.tags'         => 'you,me,she',

                ]
            );
            ok( $res->is_success, 'indicator created!' );
            is( $res->code, 201, 'created!' );
            use JSON qw(decode_json);
            my $indicator = eval{decode_json( $res->content )};
            ok(
                my $save_test =
                $schema->resultset('Indicator')->find( { id => $indicator->{id} } ),
                'indicator in DB'
            );
            is( $save_test->name, 'Foo Bar', 'name ok' );
            is( $save_test->explanation, 'explanation', 'explanation ok' );
            is( $save_test->source, 'me', 'source ok' );


            use URI;
            my $uri = URI->new( $res->header('Location') );
            $uri->query_form( api_key => 'test' );

            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'indicator exists' );
            is( $res->code, 200, 'indicator exists -- 200 Success' );

            like( $res->content, qr/weekly/, 'periodo de alguma variavel' );

            ( $res, $c ) = ctx_request( GET '/api/indicator?api_key=test');

            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;


use JSON qw(decode_json);
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
            'variable.create.period'       => $period||'week',
            'variable.create.source'       => 'God',
        ]
    );
    if ($res->code == 201){
        my $xx = eval{decode_json( $res->content )};
        return $xx->{id};
    }else{
        die('fail to create new var: ' . $res->code);
    }
}

