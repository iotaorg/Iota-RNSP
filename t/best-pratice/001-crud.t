
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
                POST '/api/best_pratice',
                [
                    api_key                           => 'test',
                    'best_pratice.create.name'        => 'FooBar',
                    'best_pratice.create.description' => 'xx',
                    'best_pratice.create.axis_id'     => '2',
                ]
            );

            ok( $res->is_success, 'best_pratice created!' );
            is( $res->code, 201, 'created!' );

            use URI;
            my $uri = URI->new( $res->header('Location') );
            $uri->query_form( api_key => 'test' );

            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'best_pratice exists' );
            is( $res->code, 200, 'best_pratice exists -- 200 Success' );

            like( $res->content, qr|FooBar|, 'FooBar ok' );

            my $obj_uri = $uri->path_query;
            ( $res, $c ) = ctx_request(
                POST $obj_uri,
                [
                    'best_pratice.update.name'        => 'BarFoo',
                    'best_pratice.update.description' => 'aa',

                ]
            );
            ok( $res->is_success, 'best_pratice updated' );
            is( $res->code, 202, 'best_pratice updated -- 202 Accepted' );

            use JSON qw(from_json);
            my $best_pratice = eval { from_json( $res->content ) };
            ok(
                my $updated_best_pratice = $schema->resultset('UserBestPratice')->find( { id => $best_pratice->{id} } ),
                'best_pratice in DB'
            );
            is( $updated_best_pratice->name,        'BarFoo', 'name ok' );
            is( $updated_best_pratice->description, 'aa',     'content ok' );

            ( $res, $c ) = ctx_request( GET '/api/best_pratice?api_key=test' );
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );

            my $list = eval { from_json( $res->content ) };
            is( $list->{best_pratices}[0]{name}, 'BarFoo', 'name from list ok' );

            ( $res, $c ) = ctx_request( DELETE $obj_uri );
            ok( $res->is_success, 'best_pratice deleted' );
            is( $res->code, 204, 'best_pratice deleted -- 204' );

            ( $res, $c ) = ctx_request( GET '/api/best_pratice?api_key=test' );
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );

            $list = eval { from_json( $res->content ) };
            is( @{ $list->{best_pratices} }, '0', 'empty list' );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
