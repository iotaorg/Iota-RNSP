
use strict;
use warnings;
use utf8;
use Test::More;
use JSON;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(Iota);

use HTTP::Request::Common;
use Package::Stash;

use Iota::TestOnly::Mock::AuthUser;

my $schema = Iota->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::TestOnly::Mock::AuthUser->new;

$Iota::TestOnly::Mock::AuthUser::_id    = 1;
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );
my $seq = 0;
eval {
    $schema->txn_do(
        sub {
            my ( $res, $c );
            ( $res, $c ) = ctx_request(
                POST '/api/indicator',
                [
                    api_key                 => 'test',
                    'indicator.create.name' => 'FooBar',
                ]
            );
            ok( !$res->is_success, 'invalid request' );
            is( $res->code, 400, 'invalid request' );

            ( $res, $c ) = ctx_request(
                POST '/api/axis-dim1',
                [
                    api_key                        => 'test',
                    'axis_dim1.create.name'        => 'gravidas',
                    'axis_dim1.create.description' => 'Descr',
                ]
            );

            ok( $res->is_success, 'axis created!' );
            is( $res->code, 201, 'created!' );
            my $dim_id = decode_json $res->content;

            ( $res, $c ) = ctx_request(
                POST '/api/axis-dim2',
                [
                    api_key                        => 'test',
                    'axis_dim2.create.name'        => '0 a 5',
                    'axis_dim2.create.description' => 'Descr',
                ]
            );

            ok( $res->is_success, 'axis created!' );
            is( $res->code, 201, 'created!' );
            my $cat_id = decode_json $res->content;

            my $var1 = &new_var( 'int', 'weekly' );

            ( $res, $c ) = ctx_request(
                POST '/api/indicator',
                [
                    api_key                          => 'test',
                    'indicator.create.name'          => 'Divisão Modal',
                    'indicator.create.formula'       => '5 + $' . $var1,
                    'indicator.create.axis_id'       => '1',
                    'indicator.create.axis_dim1_id'  => $dim_id->{id},
                    'indicator.create.axis_dim2_id'  => $cat_id->{id},
                    'indicator.create.explanation'   => 'explanation',
                    'indicator.create.source'        => 'me',
                    'indicator.create.goal_source'   => '@fulano',
                    'indicator.create.chart_name'    => 'pie',
                    'indicator.create.goal_operator' => '>=',
                    'indicator.create.tags'          => 'you,me,she',

                    'indicator.create.observations'        => 'lala',
                    'indicator.create.visibility_level'    => 'restrict',
                    'indicator.create.visibility_users_id' => '4',

                ]
            );

            ok( $res->is_success, 'indicator created!' );
            is( $res->code, 201, 'created!' );

            my $indicator = eval { from_json( $res->content ) };

            ok( my $save_test = $schema->resultset('Indicator')->find( { id => $indicator->{id} } ),
                'indicator in DB' );
            is( $save_test->name,          'Divisão Modal', 'name ok' );
            is( $save_test->name_url,      'divisao-modal',  'name ok' );
            is( $save_test->explanation,   'explanation',    'explanation ok' );
            is( $save_test->source,        'me',             'source ok' );
            is( $save_test->observations,  'lala',           'observations ok' );
            is( $save_test->chart_name,    'pie',            'chart_name ok' );
            is( $save_test->period,        'weekly',         'period ok' );
            is( $save_test->variable_type, 'int',            'variable_type ok' );

            is( $save_test->axis_dim1_id, $dim_id->{id} );
            is( $save_test->axis_dim2_id, $cat_id->{id});

            use URI;
            my $uri = URI->new( $res->header('Location') );
            $uri->query_form( api_key => 'test' );

            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'indicator exists' );
            is( $res->code, 200, 'indicator exists -- 200 Success' );

            like( $res->content, qr/weekly/, 'periodo de alguma variavel' );

            my $indicator_res = eval { decode_json( $res->content ) };
            is( $indicator_res->{visibility_level}, 'restrict', 'visibility_level ok' );

            is_deeply( $indicator_res->{restrict_to_users}, [4], 'restrict_to_users ok' );
            is( $indicator_res->{name}, 'Divisão Modal', 'name ok' );

            is( $indicator_res->{formula_human}, '5 + Foo Bar0', 'formula_human ok' );

            my @variables = $save_test->indicator_variables->all;
            is( $variables[0]->variable_id, $var1, 'variable saved in table' );

            # update var
            ( $res, $c ) = ctx_request(
                POST '/api/variable/' . $var1,
                [
                    'variable.update.name'   => 'BarFoo',
                    'variable.update.type'   => 'int',
                    'variable.update.period' => 'weekly',
                    'variable.update.source' => 'Lulu',
                ]
            );
            ok( $res->is_success, 'var updated' );
            is( $res->code, 202, 'var updated -- 202 Accepted' );

            $Iota::TestOnly::Mock::AuthUser::_id    = 4;
            @Iota::TestOnly::Mock::AuthUser::_roles = qw/ user /;

            ( $res, $c ) = ctx_request( GET '/api/indicator?api_key=test' );

            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );

            my $list = eval { from_json( $res->content ) };
            is( $list->{indicators}[0]{explanation}, 'explanation', 'explanation present!' );

            $Iota::TestOnly::Mock::AuthUser::_id    = 1;
            @Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

            ( $res, $c ) = ctx_request( GET '/api/log' );
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );

            my $logs = eval { from_json( $res->content ) };
            foreach my $log ( @{ $logs->{logs} } ) {
                if ( $log->{message} eq 'Adicionou variavel Foo Bar0' ) {
                    is( $log->{url}, 'POST /api/variable', 'Log criado com sucesso' );
                }
                elsif ( $log->{message} eq 'Adicionou indicadorFoo Bar' ) {
                    is( $log->{url}, 'POST /api/indicator', 'Log do indicador criado com sucesso' );
                }
            }

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;

sub new_var {
    my $type   = shift;
    my $period = shift;
    my ( $res, $c ) = ctx_request(
        POST '/api/variable',
        [
            api_key                       => 'test',
            'variable.create.name'        => 'Foo Bar' . $seq++,
            'variable.create.cognomen'    => 'foobar' . $seq++,
            'variable.create.explanation' => 'a foo with bar' . $seq++,
            'variable.create.type'        => $type,
            'variable.create.period'      => $period || 'week',
            'variable.create.source'      => 'God',
        ]
    );
    if ( $res->code == 201 ) {
        my $xx = eval { from_json( $res->content ) };
        return $xx->{id};
    }
    else {
        die( 'fail to create new var: ' . $res->code );
    }
}

