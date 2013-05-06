
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(Iota);

use HTTP::Request::Common qw(GET POST DELETE PUT);

use Package::Stash;

use Iota::TestOnly::Mock::AuthUser;

my $schema = Iota->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::TestOnly::Mock::AuthUser->new;

$Iota::TestOnly::Mock::AuthUser::_id    = 1;
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

eval {
    $schema->txn_do(
        sub {
            my ( $res, $c );
            ( $res, $c ) = ctx_request(
                POST '/api/measurement_unit',
                [
                    api_key                              => 'test',
                    'measurement_unit.create.name'       => 'FooBar',
                    'measurement_unit.create.short_name' => 'foo',
                ]
            );

            ok( $res->is_success, 'measurement_unit created!' );
            is( $res->code, 201, 'created!' );

            use URI;
            my $uri = URI->new( $res->header('Location') );
            $uri->query_form( api_key => 'test' );

            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'measurement_unit exists' );
            is( $res->code, 200, 'measurement_unit exists -- 200 Success' );

            like( $res->content, qr|FooBar|, 'FooBar ok' );

            my $obj_uri = $uri->path_query;
            ( $res, $c ) = ctx_request(
                POST $obj_uri,
                [
                    'measurement_unit.update.name'       => 'BarFoo',
                    'measurement_unit.update.short_name' => 'bar',
                ]
            );
            ok( $res->is_success, 'measurement_unit updated' );
            is( $res->code, 202, 'measurement_unit updated -- 202 Accepted' );

            use JSON qw(from_json);
            my $measurement_unit = eval { from_json( $res->content ) };
            ok(
                my $updated_measurement_unit =
                  $schema->resultset('MeasurementUnit')->find( { id => $measurement_unit->{id} } ),
                'measurement_unit in DB'
            );
            is( $updated_measurement_unit->name, 'BarFoo', 'name ok' );

            ( $res, $c ) = ctx_request( GET '/api/measurement_unit?api_key=test' );
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );

            my $list = eval { from_json( $res->content ) };
            is( $list->{measurement_units}[4]{name},       'BarFoo', 'name from list ok' );
            is( $list->{measurement_units}[4]{short_name}, 'bar',    'bar from list ok' );

            ( $res, $c ) = ctx_request( DELETE $obj_uri );
            ok( $res->is_success, 'measurement_unit deleted' );
            is( $res->code, 204, 'measurement_unit deleted -- 204' );

            ( $res, $c ) = ctx_request( GET '/api/measurement_unit?api_key=test' );
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );

            $list = eval { from_json( $res->content ) };
            is( @{ $list->{measurement_units} }, '4', 'default list' );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
