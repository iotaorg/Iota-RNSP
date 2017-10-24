use common::sense;

use FindBin qw($Bin);
use lib "$Bin/./lib";
use Iota::Test::Further;

use Catalyst::Test q(Iota);
use HTTP::Request::Common qw(GET POST DELETE PUT);
use Package::Stash;

use Iota::TestOnly::Mock::AuthUser;

my $schema = Iota->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::TestOnly::Mock::AuthUser->new;

$Iota::TestOnly::Mock::AuthUser::_id    = 2;
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

db_transaction {

    rest_post '/api/city',
      name   => 'Created City',
      stash  => 'city',
      code   => 201,
      params => [
        api_key                 => 'test',
        'city.create.name'      => 'Foo Bar',
        'city.create.state_id'  => 1,
        'city.create.latitude'  => 5666.55,
        'city.create.longitude' => 1000.11,

      ],
      ;

    $schema->resultset('User')->search( { id => 4 } )->update( { city_id => stash 'city.id' } );

    rest_post stash('city.url') . '/region',
      name   => 'Create Region',
      stash  => 'reg',
      code   => 201,
      params => [
        api_key                                     => 'test',
        'city.region.create.name'                   => 'a region',
        'city.region.create.polygon_path'           => 'str',
        'city.region.create.subregions_valid_after' => '2015-01-01',
        'city.region.create.description'            => 'with no description',
      ],
      ;

    my $var1 = &new_var( 'int', 'yearly' );

    rest_post '/api/indicator',
      name   => "Indicator Created",
      stash  => "ind",
      code   => 201,
      params => [
        api_key                          => 'test',
        'indicator.create.name'          => 'Divisão Modal',
        'indicator.create.formula'       => '5 + $' . $var1,
        'indicator.create.axis_id'       => '1',
        'indicator.create.explanation'   => 'explanation',
        'indicator.create.source'        => 'me',
        'indicator.create.goal_source'   => '@fulano',
        'indicator.create.chart_name'    => 'pie',
        'indicator.create.goal_operator' => '>=',
        'indicator.create.tags'          => 'you,me,she',

        'indicator.create.observations'        => 'lala',
        'indicator.create.visibility_level'    => 'public',
        'indicator.create.visibility_users_id' => '4',

      ],
      ;
    $Iota::TestOnly::Mock::AuthUser::_id = 4;
    rest_put stash('reg.url') . '/value',
      name   => "Dado pro ano questionado",
      stash  => 'value',
      code   => 201,
      params => [
        'region.variable.value.put.value'         => '123',
        'region.variable.value.put.variable_id'   => $var1,
        'region.variable.value.put.value_of_date' => '2012-10-10 14:22:44',
        'region.variable.value.put.source'        => 'bazar',
      ],
      ;

    rest_get "api/public/indicator-availability-city-year",
      name   => "Institute Created",
      stash  => "ins",
      code   => 200,
      params => [
        'city_id'     => stash 'city.id',
        'depth_level' => 2,
        'periods'     => 2012,

      ],
      ;

    rest_get "api/public/indicator-availability-city-year",
      name   => "Institute Created",
      stash  => "ins2",
      code   => 200,
      params => [
        'city_id'     => stash 'city.id',
        'depth_level' => 3,
        'periods'     => 2012,

      ],
      ;

    stash_test 'ins' => sub {
        my $me = shift;

        is( $me->{indicators}[0]{id}, stash 'ind.id', 'indicador com dado DEPTH = 2' );
    };

    stash_test 'ins2' => sub {
        my $me = shift;

        is_deeply( $me->{indicators}, [], 'Nenhum dado DEPTH = 3' );
    };

};

done_testing;
