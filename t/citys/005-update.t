

use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(Iota::PCS);

use HTTP::Request::Common;
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
            [   api_key            => 'test',
                'city.create.name' => 'Foo Bar',
                'city.create.pais' => 'foobar',
                'city.create.uf'   => 'XX',
            ]
        );
        ok( $res->is_success, 'city created!' );
        is( $res->code, 201, 'created!' );

        use URI;
        my $uri = URI->new( $res->header('Location') );
        $uri->query_form( api_key => 'test' );


        # update var
        ( $res, $c ) = ctx_request(
            POST $uri->path_query,
            [
                'city.update.name'         => 'BarFoo',
                'city.update.uf'           => 'XX',
                'city.update.longitude'    => 55.55,
            ]
        );
        ok( $res->is_success, 'var updated' );
        is( $res->code, 202, 'var updated -- 202 Accepted' );

        ( $res, $c ) = ctx_request(
            POST $uri->path_query,
            [
                'city.update.name'         => 'BarFoo',
                'city.update.uf'           => 'XX',
                'city.update.longitude'    => 55.55,
            ]
        );
        ok( $res->is_success, 'var updated' );
        is( $res->code, 202, 'var updated -- 202 Accepted' );

        use JSON qw(from_json);
        my $city = eval{from_json( $res->content )};
        ok(
            my $updated_var =
            $schema->resultset('City')->find( { id => $city->{id} } ),
            'var in DB'
        );

        is( $updated_var->longitude, '55.55', 'longitude ok' );
        is( $updated_var->name, 'BarFoo', 'name ok' );

      die 'rollback';
    }
  );

};

die $@ unless $@ =~ /rollback/;

done_testing;
