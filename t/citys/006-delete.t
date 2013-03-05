
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(Iota::PCS);

use HTTP::Request::Common qw(GET POST DELETE PUT);
;
use Package::Stash;

use Iota::PCS::TestOnly::Mock::AuthUser;

my $schema = Iota::PCS->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::PCS::TestOnly::Mock::AuthUser->new;

$Iota::PCS::TestOnly::Mock::AuthUser::_id    = 1;
@Iota::PCS::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );


eval {
  $schema->txn_do(
    sub {

      my ( $res, $c );

      ( $res, $c ) = ctx_request(
            POST '/api/city',
            [   api_key                        => 'test',
                'city.create.name'      => 'Foo Bar',
                'city.create.uf'        => 'XU',
                'city.create.pais'      => 'USA',
                'city.create.latitude'  => 5666.55,
                'city.create.longitude' => 1000.11,
            ]
        );
        ok( $res->is_success, 'city created!' );
        is( $res->code, 201, 'created!' );

        use URI;
        my $uri = URI->new( $res->header('Location') );
        $uri->query_form( api_key => 'test' );

      # delete var
      ( $res, $c ) =
        ctx_request( DELETE  $uri->path_query );
      ok( $res->is_success, 'var deleted' );
      is( $res->code, 204, 'var deleted - 204 no content' );



      die 'rollback';

    }
  );
};

die $@ unless $@ =~ /rollback/;

done_testing;

