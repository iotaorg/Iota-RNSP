
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
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ superadmin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

eval {
    $schema->txn_do(
        sub {
            my ( $res, $c );
            ( $res, $c ) = ctx_request(
                POST '/api/network',
                [
                    api_key                       => 'test',
                    'network.create.name'         => 'prefeitura nao lembro o nome',
                    'network.create.name_url'     => 'prefeitura-2',
                    'network.create.domain_name'  => 'foo-domain.org',
                    'network.create.institute_id' => '1',

                ]
            );

            ok( $res->is_success, 'network created!' );
            is( $res->code, 201, 'created!' );

            use URI;
            my $uri = URI->new( $res->header('Location') );
            $uri->query_form( api_key => 'test' );

            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'network exists' );
            is( $res->code, 200, 'network exists -- 200 Success' );

            like( $res->content, qr|"prefeitura nao lembro o nome"|, 'name ok' );
            like( $res->content, qr|"prefeitura-2"|, 'name_url ok' );

            my $obj_uri = $uri->path_query;
            ( $res, $c ) = ctx_request(
                POST $obj_uri,
                [
                    'network.update.name' => 'BarFoo',

                ]
            );
            ok( $res->is_success, 'network updated' );
            is( $res->code, 202, 'network updated -- 202 Accepted' );

            use JSON qw(from_json);
            my $network = eval { from_json( $res->content ) };
            ok( my $updated_network = $schema->resultset('Network')->find( { id => $network->{id} } ),
                'network in DB' );
            is( $updated_network->name, 'BarFoo', 'name ok' );
            ok( $updated_network->domain_name, 'foo-domain.org' );

            ( $res, $c ) = ctx_request( GET '/api/network?api_key=test' );
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );

            my $list = eval { from_json( $res->content ) };
            is( $list->{network}[3]{name}, 'BarFoo', 'name from list ok' );

            ( $res, $c ) = ctx_request( DELETE $obj_uri );
            ok( $res->is_success, 'network deleted' );
            is( $res->code, 204, 'network deleted -- 204' );

            ( $res, $c ) = ctx_request( GET '/api/network?api_key=test' );
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );

            $list = eval { from_json( $res->content ) };
            is( @{ $list->{network} }, '3', 'default list' );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
