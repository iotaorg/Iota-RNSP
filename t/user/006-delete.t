
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(Iota);

use HTTP::Request::Common qw(GET POST DELETE PUT);
;
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
        my $city = $schema->resultset('City')->create(
            {
                uf   => 'SP',
                name => 'Pederneiras'
            },
        );
      my ( $res, $c ) = ctx_request(
        POST '/api/user',
        [
          api_key                        => 'test',
          'user.create.name'             => 'Foo Bar',
          'user.create.email'            => 'foo@email.com',
          'user.create.password'         => 'foobarquux1',
          'user.create.password_confirm' => 'foobarquux1',
          'user.create.role'             => 'user',
          'user.create.city_id'          => $city->id,
        ]
      );

      ok(
        my $new_user =
          $schema->resultset('User')->find( { email => 'foo@email.com' } ),
        'user in DB'
      );

      # delete user
      ( $res, $c ) =
        ctx_request( DELETE '/api/user/' . $new_user->id . '?api_key=test' );
      ok( $res->is_success, 'user deleted' );
      is( $res->code, 204, 'user deleted - 204 no content' );

      # delete inexistent user
      #( $res, $c ) =
      #  ctx_request( DELETE '/api/user/' . $new_user->id . '?api_key=test' );
      #ok( !$res->is_success, 'error -- inexistent user' );
      #is( $res->code, 404, 'error -- inexistent user -- 404 Not found ' );

      die 'rollback';

    }
  );
};

die $@ unless $@ =~ /rollback/;

done_testing;

