
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(Iota);

use HTTP::Request::Common;
use Package::Stash;

use JSON;
use Iota::TestOnly::Mock::AuthUser;

my $schema = Iota->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::TestOnly::Mock::AuthUser->new;

$Iota::TestOnly::Mock::AuthUser::_id    = 1;
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

use JSON qw(from_json);
eval {
    $schema->txn_do(
        sub {
            my ( $res, $c );

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
                POST '/api/indicator',
                [
                    api_key                    => 'test',
                    'indicator.create.name'    => 'Foo Bar',
                    'indicator.create.goal'    => '11',
                    'indicator.create.formula' => '5 / 2',
                    'indicator.create.axis_id' => '1',
                    'indicator.create.axis_dim1_id'  => $dim_id->{id},
                    'indicator.create.visibility_level' => 'public',
                ]
            );
            ok( $res->is_success, 'indicator created!' );
            is( $res->code, 201, 'created!' );

            use URI;
            my $uri = URI->new( $res->header('Location') );
            $uri->query_form( api_key => 'test' );

            # update indicator
            ( $res, $c ) = ctx_request( POST $uri->path_query, [ 'indicator.update.goal' => '22', ] );
            ok( $res->is_success, 'indicator updated' );
            is( $res->code, 202, 'indicator updated -- 202 Accepted' );
            my $indicator = eval { from_json( $res->content ) };
            ok( my $updated_indicator = $schema->resultset('Indicator')->find( { id => $indicator->{id} } ),
                'indicator in DB' );

            is( $updated_indicator->name, 'Foo Bar', 'name not change!' );
            is( $updated_indicator->goal, '22',      'goal updated ok' );

            #####################

            ( $res, $c ) = ctx_request(
                POST $uri->path_query,
                [
                    'indicator.update.goal'               => '23',
                    'indicator.update.visibility_level'   => 'private',
                    'indicator.update.visibility_user_id' => '4',
                ]
            );
            ok( $res->is_success, 'indicator updated' );
            is( $res->code, 202, 'indicator updated -- 202 Accepted' );

            ok( $updated_indicator = $schema->resultset('Indicator')->find( { id => $indicator->{id} } ),
                'indicator in DB' );

            is( $updated_indicator->goal,               '23', 'goal updated ok' );
            is( $updated_indicator->visibility_user_id, '4',  'visibility_user_id ok' );

            #####################

            ( $res, $c ) = ctx_request(
                POST $uri->path_query,
                [
                    'indicator.update.goal' => '23',
                    'indicator.update.axis_dim1_id' => '',
                ]
            );
            ok( $res->is_success, 'indicator updated!' );
            do {
                ok( my $local = $schema->resultset('Indicator')->find( { id => $indicator->{id} } ),
                'indicator in DB' );

                is( $local->axis_dim1_id, $dim_id->{id}, 'keep same dim' );
            };
            # again, but remove dim
            ( $res, $c ) = ctx_request(
                POST $uri->path_query,
                [
                    'indicator.update.goal' => '23',
                    'indicator.update.axis_dim1_id' => '0',
                ]
            );
            ok( $res->is_success, 'indicator updated!' );
            do {
                ok( my $local = $schema->resultset('Indicator')->find( { id => $indicator->{id} } ),
                'indicator in DB' );

                is( $local->axis_dim1_id, undef, 'removed dimension' );
            };

            ( $res, $c ) = ctx_request(
                POST $uri->path_query,
                [
                    'indicator.update.goal'             => '23',
                    'indicator.update.visibility_level' => 'private',
                ]
            );
            ok( !$res->is_success, 'indicator not updated' );

            #####################

            ( $res, $c ) = ctx_request(
                POST $uri->path_query,
                [
                    'indicator.update.goal'                   => '25',
                    'indicator.update.visibility_level'       => 'network',
                    'indicator.update.visibility_networks_id' => '1,2',
                ]
            );

            ok( $res->is_success, 'indicator updated' );
            is( $res->code, 202, 'indicator updated -- 202 Accepted' );

            ok( $updated_indicator = $schema->resultset('Indicator')->find( { id => $indicator->{id} } ),
                'indicator in DB' );

            is( $updated_indicator->goal,                                  '25', 'goal updated ok' );
            is( $updated_indicator->indicator_network_visibilities->count, '2',  'visibility_networks ok' );

            #####################

            ( $res, $c ) = ctx_request(
                POST $uri->path_query,
                [
                    'indicator.update.goal'                => '26',
                    'indicator.update.visibility_level'    => 'restrict',
                    'indicator.update.visibility_users_id' => '4,7',
                ]
            );

            ok( $res->is_success, 'indicator updated' );
            is( $res->code, 202, 'indicator updated -- 202 Accepted' );

            ok( $updated_indicator = $schema->resultset('Indicator')->find( { id => $indicator->{id} } ),
                'indicator in DB' );

            is( $updated_indicator->goal, '26', 'goal updated ok' );
            is_deeply(
                [ sort map { $_->user_id } $updated_indicator->indicator_user_visibilities ],
                [ 4, 7 ],
                'indicator_user_visibilities ok'
            );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
