

use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(RNSP::PCS);

use HTTP::Request::Common;
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
          'user.create.city_id'          => $city->id,
        ]
      );
      ok( $res->is_success, 'user created' );
      is( $res->code, 201, 'user created' );
      ok(
        my $new_user =
          $schema->resultset('User')->find( { email => 'foo@email.com' } ),
        'user in DB'
      );

      {
        use JSON qw(decode_json);
        is( decode_json( $res->content )->{name}, $new_user->name,
          'same user' );
      }
      like( $res->header('Location'), qr{/api/user/\d+$}, 'location ok' );

      use JSON qw(encode_json);

      # update user
      ( $res, $c ) = ctx_request(
        POST '/api/user/' . $new_user->id,
        [
          api_key                        => 'test',
          'user.update.name'             => 'Foo Bar',
          'user.update.email'            => 'bar@email.com',
          'user.update.password'         => 'foobarquux1',
          'user.update.password_confirm' => 'foobarquux1',
        ]
      );
      ok( $res->is_success, 'user updated' );
      is( $res->code, 202, 'user updated -- 202 Accepted' );


      ok(
        my $updated_user =
          $schema->resultset('User')->find( { email => 'bar@email.com' } ),
        'user in DB'
      );

      is( $new_user->id, $updated_user->id, 'same user' );


      die 'rollback';
    }
  );

};

die $@ unless $@ =~ /rollback/;

done_testing;
