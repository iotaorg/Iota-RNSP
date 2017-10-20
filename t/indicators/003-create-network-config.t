use common::sense;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Iota::Test::Further;

use Catalyst::Test q(Iota);
use HTTP::Request::Common;
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

    rest_post 'api/indicator',
      name    => "Invalid Request",
      stash   => "ind",
      code    => 400,
      is_fail => 1,
      params  => [
        api_key                 => 'test',
        'indicator.create.name' => 'FooBar',
      ],
      ;

    rest_post '/api/indicator',
      name   => "Indicator Created",
      stash  => "ind",
      code   => 201,
      params => [
        api_key                          => 'test',
        'indicator.create.name'          => 'Foo Bar',
        'indicator.create.formula'       => '1',
        'indicator.create.axis_id'       => '1',
        'indicator.create.explanation'   => 'explanation',
        'indicator.create.source'        => 'me',
        'indicator.create.goal_source'   => '@fulano',
        'indicator.create.chart_name'    => 'pie',
        'indicator.create.goal_operator' => '>=',
        'indicator.create.tags'          => 'you,me,she',

        'indicator.create.visibility_level' => 'public',
        'indicator.create.observations'     => 'lala'
      ],
      ;

    rest_get stash("ind.url") . "/network_config",
      name  => "URL network_config",
      stash => "url_conf",
      code  => "200",
      ;

    stash_test "url_conf" => sub {
        my $list = shift;

        is_deeply( $list->{network_configs}, [], 'empty list' );
    };

    rest_post stash("ind.url") . '/network_config/1',
      name   => "network_config 1",
      stash  => "conf_1",
      code   => 202,
      params => [
        api_key                                            => 'test',
        'indicator.network_config.upsert.unfolded_in_home' => 1,
      ];

    stash_test "conf_1" => sub {
        my $insert = shift;

        is_deeply(
            $insert,
            {
                indicator_id => stash "ind.id",
                network_id   => 1
            },
            'Ok insert 1'
        );
    };

    rest_post stash("ind.url") . '/network_config/2',
      name   => "network_config 2",
      stash  => "conf_2",
      code   => 202,
      params => [
        api_key                                            => 'test',
        'indicator.network_config.upsert.unfolded_in_home' => 1,
      ],
      ;

    #Declarado aqui pois será usado depois
    my $insert2 = undef;

    stash_test "conf_2" => sub {
        $insert2 = shift;

        is_deeply(
            $insert2,
            {
                indicator_id => stash "ind.id",
                network_id   => 2
            },
            'Ok insert 2'
        );
    };

    rest_get stash("ind.url") . "/network_config",
      name  => "URL network_config",
      stash => "url_conf",
      code  => "200",
      ;

    stash_test "url_conf" => sub {
        my $list = shift;

        is( @{ $list->{network_configs} }, 2, '2 itens' );
        is( $_->{unfolded_in_home}, 1, 'ok' ) for @{ $list->{network_configs} };

    };

    rest_post stash("ind.url") . '/network_config/2',
      name   => "network_config 2 novamente",
      stash  => "conf_2",
      code   => 202,
      params => [
        api_key                                            => 'test',
        'indicator.network_config.upsert.unfolded_in_home' => 0,
      ],
      ;

    stash_test "conf_2" => sub {

        is_deeply( shift, $insert2, 'Same insert, same result' );

    };

    rest_get stash("ind.url") . "/network_config/2",
      name  => "network_config 2",
      stash => "conf_2",
      code  => "200",
      ;

    stash_test "conf_2" => sub {
        my $item = shift;

        is_deeply( $item, { unfolded_in_home => 0 }, 'Item updated !! ' );
    };

    rest_get stash("ind.url"),
      name  => "Listing ok",
      stash => "list",
      code  => "200",
      ;

    stash_test "list" => sub {
        my $list_ind = shift;

        is( @{ $list_ind->{network_configs} }, 2, '2 network_configs in detais of indicator' );
    };

    for ( 1 .. 2 ) {
        rest_delete stash("ind.url") . "/network_config/" . $_,
          name  => "Indicator" . $_ . " deleted",
          stash => "uri",
          code  => 204,
          ;
    }

    rest_get stash("ind.url") . "/network_config",
      name  => "URL network_config",
      stash => "url_conf",
      code  => "200",
      ;
    stash_test "url_conf" => sub {
        my $list = shift;

        is_deeply( $list->{network_configs}, [], 'empty list' );
    };

};

done_testing;
