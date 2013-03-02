
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(RNSP::PCS);


use HTTP::Request::Common qw(GET POST DELETE PUT);

use Package::Stash;

use RNSP::PCS::TestOnly::Mock::AuthUser;

my $schema = RNSP::PCS->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = RNSP::PCS::TestOnly::Mock::AuthUser->new;

$RNSP::PCS::TestOnly::Mock::AuthUser::_id    = 1;
@RNSP::PCS::TestOnly::Mock::AuthUser::_roles = qw/ user /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

eval {
    $schema->txn_do(
        sub {
            my ( $res, $c );
            ( $res, $c ) = ctx_request(
                POST '/api/user_indicator_axis',
                [   api_key                    => 'test',
                    'user_indicator_axis.create.name'       => 'FooBar',
                ]
            );

            ok( $res->is_success, 'user_indicator_axis created!' );
            is( $res->code, 201, 'created!' );

            use URI;
            my $uri = URI->new( $res->header('Location') );
            $uri->query_form( api_key => 'test' );

            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'user_indicator_axis exists' );
            is( $res->code, 200, 'user_indicator_axis exists -- 200 Success' );

            like($res->content, qr|FooBar|, 'FooBar ok');


            my $obj_uri = $uri->path_query;
            ( $res, $c ) = ctx_request(
                POST $obj_uri,
                [
                    'user_indicator_axis.update.name'         => 'BarFoo',
                ]
            );
            ok( $res->is_success, 'user_indicator_axis updated' );
            is( $res->code, 202, 'user_indicator_axis updated -- 202 Accepted' );

            use JSON qw(from_json);
            my $user_indicator_axis = eval{from_json( $res->content )};
            ok(
                my $updated_user_indicator_axis =
                $schema->resultset('UserIndicatorAxis')->find( { id => $user_indicator_axis->{id} } ),
                'user_indicator_axis in DB'
            );
            is( $updated_user_indicator_axis->name, 'BarFoo', 'name ok' );

            ( $res, $c ) = ctx_request( GET '/api/user_indicator_axis?api_key=test');
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );

            my $list = eval{from_json( $res->content )};
            is($list->{user_indicator_axis}[0]{name}, 'BarFoo', 'name from list ok');

            # com id
            ( $res, $c ) = ctx_request( GET '/api/user_indicator_axis?api_key=test&indicator_id=1');
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );

            $list = eval{from_json( $res->content )};
            is(@{$list->{user_indicator_axis}}, '0', 'empty list');


            ( $res, $c ) = ctx_request(
                DELETE $obj_uri
            );
            ok( $res->is_success, 'user_indicator_axis deleted' );
            is( $res->code, 204, 'user_indicator_axis deleted -- 204' );

            ( $res, $c ) = ctx_request( GET '/api/user_indicator_axis?api_key=test');
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );


            $list = eval{from_json( $res->content )};
            is(@{$list->{user_indicator_axis}}, '0', 'empty list');

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
