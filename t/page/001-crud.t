
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
                POST '/api/page',
                [
                    api_key               => 'test',
                    'page.create.title'   => 'FooBar',
                    'page.create.content' => 'xx',
                ]
            );

            ok( $res->is_success, 'page created!' );
            is( $res->code, 201, 'created!' );

            use URI;
            my $uri = URI->new( $res->header('Location') );
            $uri->query_form( api_key => 'test' );

            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'page exists' );
            is( $res->code, 200, 'page exists -- 200 Success' );

            like( $res->content, qr|FooBar|, 'FooBar ok' );

            my $obj_uri = $uri->path_query;
            ( $res, $c ) = ctx_request(
                POST $obj_uri,
                [
                    'page.update.title'        => 'BarFoo',
                    'page.update.content'      => 'aa',
                    'page.update.published_at' => '2010-01-02'
                ]
            );
            ok( $res->is_success, 'page updated' );
            is( $res->code, 202, 'page updated -- 202 Accepted' );

            use JSON qw(from_json);
            my $page = eval { from_json( $res->content ) };
            ok( my $updated_page = $schema->resultset('UserPage')->find( { id => $page->{id} } ), 'page in DB' );
            is( $updated_page->title,   'BarFoo', 'title ok' );
            is( $updated_page->content, 'aa',     'content ok' );
            like( $updated_page->published_at->dmy, qr/2010/, 'published_at' );

            ( $res, $c ) = ctx_request( GET '/api/page?api_key=test' );
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );

            my $list = eval { from_json( $res->content ) };
            is( $list->{pages}[0]{title}, 'BarFoo', 'title from list ok' );

            ( $res, $c ) = ctx_request( DELETE $obj_uri );
            ok( $res->is_success, 'page deleted' );
            is( $res->code, 204, 'page deleted -- 204' );

            ( $res, $c ) = ctx_request( GET '/api/page?api_key=test' );
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );

            $list = eval { from_json( $res->content ) };
            is( @{ $list->{pages} }, '0', 'empty list' );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
