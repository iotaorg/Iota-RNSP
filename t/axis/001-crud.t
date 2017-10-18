use common::sense;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Iota::Test::Further;

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

db_transaction {

    rest_post "/api/axis",
      name   => "Axis Created",
      stash  => "l1",
      code   => 201,
      params => [
        api_key                   => "test",
        'axis.create.name'        => "FooBar",
        'axis.create.description' => "42scriptia",
      ],
      ;

    rest_get stash('l1.url'),
      name  => "Sucess",
      stash => "l2",
      code  => 200;

    stash_test 'l2' => sub {
        my $res = shift;

        is( $res->{name},        'FooBar',     'Name = Foobar' );
        is( $res->{description}, '42scriptia', 'Description = 42' );
    };

    rest_post stash("l1.url") . "?api_key=test",
      name   => "Axis Exists",
      stash  => "l1",
      code   => 202,
      params => [ 'axis.update.name' => 'BarFoo' ],
      ;

    stash_test 'l1' => sub {
        my $res = shift;

        is( $res->{name},        'BarFoo', 'NameUpdate = BarFoo' );
        is( $res->{description}, undef,    'Description = Undef' );
        ok( $schema->resultset("Axis")->find( stash 'l1.id' ), 'Axis in DB', );
    };

    rest_get '/api/axis',
      name   => "Listing OK",
      stash  => "l1",
      params => [ api_key => 'test' ],
      code   => 200;

    stash_test 'l1' => sub {
        my $res = shift;
        is( $res->{axis}[13]{name}, 'BarFoo', 'Name from list OK' );
    };

    rest_delete stash("l1.url") . "?api_key=test",
      name  => "Axis Deleted",
      stash => "l1",
      code  => 204;

    rest_get '/api/axis',
      name   => "Listing OK",
      stash  => "l1",
      params => [ api_key => 'test' ],
      code   => 200;

    stash_test 'l1' => sub {
        my $res = shift;
        is( @{ $res->{axis} }, '13', 'Default List' );
    };

};

done_testing;
