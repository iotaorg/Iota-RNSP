
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(RNSP::PCS);

use HTTP::Request::Common qw(GET POST DELETE PUT);
;
use Package::Stash;

use RNSP::PCS::TestOnly::Mock::AuthUser;

my $schema = RNSP::PCS->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = RNSP::PCS::TestOnly::Mock::AuthUser->new;

$RNSP::PCS::TestOnly::Mock::AuthUser::_id    = 1;
@RNSP::PCS::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );


eval {
  $schema->txn_do(
    sub {

      my ( $res, $c );

      ( $res, $c ) = ctx_request(
            POST '/api/indicator',
            [   api_key                        => 'test',
                'indicator.create.name'         => 'Foo Bar',
                'indicator.create.formula'      => '$A + $B',
                'indicator.create.goal'         => '33',
                'indicator.create.axis'         => 'Y',
            ]
        );
        ok( $res->is_success, 'indicator created!' );
        is( $res->code, 201, 'created!' );

        use URI;
        my $uri = URI->new( $res->header('Location') );
        $uri->query_form( api_key => 'test' );

      # delete indicator
      ( $res, $c ) =
        ctx_request( DELETE  $uri->path_query );
      ok( $res->is_success, 'indicator deleted' );
      is( $res->code, 204, 'indicator deleted - 204 no content' );



      die 'rollback';

    }
  );
};

die $@ unless $@ =~ /rollback/;

done_testing;

