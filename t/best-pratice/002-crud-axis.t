
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
                    api_key               => 'test',
                    'best_pratice.create.name'   => 'teste com',
                    'best_pratice.create.axis_id' => 2,
                ]
            );

            ok( $res->is_success, 'best_pratice created!' );
            is( $res->code, 201, 'created!' );

            use JSON qw(from_json);
            my $best_pratice = eval { from_json( $res->content ) };

            my $bpurl = $res->header('Location');
            ( $res, $c ) = ctx_request(
                POST $bpurl . '/axis',
                [
                    api_key               => 'test',
                    'best_pratice.axis.create.axis_id' => 1
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

            my $axis = eval { from_json( $res->content ) };
            ok( my $updated_axis = $schema->resultset('UserBestPraticeAxis')->find( { id => $axis->{id} } ), 'axis in DB' );
            is( $updated_axis->axis_id, '1', 'axis_id ok' );


            ( $res, $c ) = ctx_request( GET $bpurl . '/axis?api_key=test' );
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );

            my $list = eval { from_json( $res->content ) };

            is( ref $list->{axis}[0], 'HASH', 'have item ok' );

            my $obj_uri = $bpurl . '/axis/' . $list->{axis}[0]->{id};
            ( $res, $c ) = ctx_request( DELETE $obj_uri );
            ok( $res->is_success, 'axis deleted' );
            is( $res->code, 204, 'axis deleted -- 204' );

            ( $res, $c ) = ctx_request( GET $bpurl . '/axis?api_key=test' );
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );use DDP; p $res;

            $list = eval { from_json( $res->content ) };
            is( @{ $list->{axis} }, '0', 'empty list' );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
