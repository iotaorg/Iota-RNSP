use common::sense;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Iota::Test::Further;

use Catalyst::Test q(Iota);
use HTTP::Request::Common qw /GET POST DELETE/;
use Package::Stash;

use Iota::TestOnly::Mock::AuthUser;

my $schema = Iota->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::TestOnly::Mock::AuthUser->new;

$Iota::TestOnly::Mock::AuthUser::_id    = 1;
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

db_transaction {

    rest_get "/api/axis",
      name   => "Axis List OK",
      stash  => "l1",
      code   => 200,
      params => [ api_key => "test" ],
      ;

    stash_test 'l1' => sub {
        my $ref = shift;

        is( ref $ref->{axis}, ref [], 'Axis is Array' );
        ok( $ref->{axis}[0]{name}, 'Defined Name' );
    };
};

done_testing;
