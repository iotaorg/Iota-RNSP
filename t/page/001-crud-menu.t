
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
                    'page.create.title'   => 'teste com',
                    'page.create.content' => 'xx',
                ]
            );

            ok( $res->is_success, 'page created!' );
            is( $res->code, 201, 'created!' );

            use JSON qw(from_json);
            my $page = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request(
                POST '/api/menu',
                [
                    api_key               => 'test',
                    'menu.create.title'   => 'menufoos',
                    'menu.create.page_id' => $page->{id}
                ]
            );

            ok( $res->is_success, 'menu created!' );
            is( $res->code, 201, 'created!' );

            use URI;
            my $uri = URI->new( $res->header('Location') );
            $uri->query_form( api_key => 'test' );

            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'menu exists' );
            is( $res->code, 200, 'menu exists -- 200 Success' );

            like( $res->content, qr|menufoos|, 'title ok' );

            my $obj_uri = $uri->path_query;
            ( $res, $c ) = ctx_request(
                POST $obj_uri,
                [
                    'menu.update.title'    => 'BarFoo',
                    'menu.update.position' => 2
                ]
            );
            ok( $res->is_success, 'menu updated' );
            is( $res->code, 202, 'menu updated -- 202 Accepted' );

            my $menu = eval { from_json( $res->content ) };
            ok( my $updated_menu = $schema->resultset('UserMenu')->find( { id => $menu->{id} } ), 'menu in DB' );
            is( $updated_menu->title,    'BarFoo', 'title ok' );
            is( $updated_menu->position, 2,        'position ok' );

            ( $res, $c ) = ctx_request( GET '/api/menu?api_key=test' );
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );

            my $list = eval { from_json( $res->content ) };
            is( $list->{menus}[0]{title},          'BarFoo',    'title from list ok' );
            is( $list->{menus}[0]{page_title_url}, 'teste-com', 'page title url from list ok' );

            ( $res, $c ) = ctx_request( DELETE $obj_uri );
            ok( $res->is_success, 'menu deleted' );
            is( $res->code, 204, 'menu deleted -- 204' );

            ( $res, $c ) = ctx_request( GET '/api/menu?api_key=test' );
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );

            $list = eval { from_json( $res->content ) };
            is( @{ $list->{menus} }, '0', 'empty list' );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
