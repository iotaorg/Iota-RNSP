
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(IOTA::PCS);


use HTTP::Request::Common qw(GET POST DELETE PUT);

use Package::Stash;

use IOTA::PCS::TestOnly::Mock::AuthUser;

my $schema = IOTA::PCS->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = IOTA::PCS::TestOnly::Mock::AuthUser->new;

$IOTA::PCS::TestOnly::Mock::AuthUser::_id    = 1;
@IOTA::PCS::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

eval {
    $schema->txn_do(
        sub {
            my ( $res, $c );
            ( $res, $c ) = ctx_request(
                POST '/api/axis',
                [   api_key                    => 'test',
                    'axis.create.name'       => 'FooBar',
                ]
            );

            ok( $res->is_success, 'axis created!' );
            is( $res->code, 201, 'created!' );

            use URI;
            my $uri = URI->new( $res->header('Location') );
            $uri->query_form( api_key => 'test' );

            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'axis exists' );
            is( $res->code, 200, 'axis exists -- 200 Success' );

            like($res->content, qr|FooBar|, 'FooBar ok');


            my $obj_uri = $uri->path_query;
            ( $res, $c ) = ctx_request(
                POST $obj_uri,
                [
                    'axis.update.name'         => 'BarFoo',
                ]
            );
            ok( $res->is_success, 'axis updated' );
            is( $res->code, 202, 'axis updated -- 202 Accepted' );

            use JSON qw(from_json);
            my $axis = eval{from_json( $res->content )};
            ok(
                my $updated_axis =
                $schema->resultset('Axis')->find( { id => $axis->{id} } ),
                'axis in DB'
            );
            is( $updated_axis->name, 'BarFoo', 'name ok' );

            ( $res, $c ) = ctx_request( GET '/api/axis?api_key=test');
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );

            my $list = eval{from_json( $res->content )};
            is($list->{axis}[13]{name}, 'BarFoo', 'name from list ok');

            ( $res, $c ) = ctx_request(
                DELETE $obj_uri
            );
            ok( $res->is_success, 'axis deleted' );
            is( $res->code, 204, 'axis deleted -- 204' );

            ( $res, $c ) = ctx_request( GET '/api/axis?api_key=test');
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );


            $list = eval{from_json( $res->content )};
            is(@{$list->{axis}}, '13', 'default list');

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
