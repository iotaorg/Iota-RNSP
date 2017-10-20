use common::sense;

#plan skip_all => 'teste comentado temporariamente pois nao existe indicadores com "roles"';

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

    my $var1 = &new_var( 'int', 'weekly' );

    rest_post '/api/indicator',
      name   => "Indicator Created",
      stash  => "ind",
      code   => 201,
      params => [
        api_key                          => 'test',
        'indicator.create.name'          => 'Foo Bar',
        'indicator.create.formula'       => '5 + $' . $var1,
        'indicator.create.axis_id'       => '1',
        'indicator.create.explanation'   => 'explanation',
        'indicator.create.source'        => 'me',
        'indicator.create.goal_source'   => '@fulano',
        'indicator.create.chart_name'    => 'pie',
        'indicator.create.goal_operator' => '>=',
        'indicator.create.tags'          => 'you,me,she',

        'indicator.create.observations'     => 'lala',
        'indicator.create.visibility_level' => 'public',
      ],
      ;

    stash_test "ind" => sub {
        ok( my $save_test = $schema->resultset('Indicator')->find( stash 'ind.id' ), 'Indicator in DB' );

        is( $save_test->name,         'Foo Bar',     'Name ok' );
        is( $save_test->explanation,  'explanation', 'Explanation ok' );
        is( $save_test->source,       'me',          'Source ok' );
        is( $save_test->observations, 'lala',        'Observations ok' );
        is( $save_test->chart_name,   'pie',         'Chart_name ok' );
    };

    rest_get stash "ind.url",
      name  => 'Indicator exists',
      stash => 'indica',
      code  => 200,
      ;

    stash_test 'indica' => sub {
        my $res = shift;

        like( $res->{period}, qr/weekly/, 'Period of some variable' );
    };

    rest_get '/api/indicator',
      name   => "Listing OK",
      stash  => "list",
      params => [ api_key => 'test' ],
      code   => 200,
      ;

    stash_test 'list' => sub {
        my $inds = shift;

        is( @{ $inds->{indicators} }, 1, 'Roles Admin ok' );
    };

    @Iota::TestOnly::Mock::AuthUser::_roles = qw/ _prefeitura /;

    rest_get '/api/indicator',
      name   => "Listing OK",
      stash  => "list",
      params => [ api_key => 'test' ],
      code   => 200,
      ;

    stash_test 'list' => sub {
        my $inds = shift;

        #is(@{$inds->{indicators}}, 1, 'Roles Prefeitura ok');
    };

    @Iota::TestOnly::Mock::AuthUser::_roles = qw/ _movimento /;

    rest_get '/api/indicator',
      name   => "Listing OK",
      stash  => "list",
      params => [ api_key => 'test' ],
      code   => 200,
      ;

    stash_test 'list' => sub {
        my $inds = shift;

        #is(@{$inds->{indicators}}, 0, 'Roles Movimento ok');
    };

    @Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

    rest_post '/api/indicator',
      name   => 'Indicator Created!',
      stash  => 'Indicator',
      code   => 201,
      params => [
        api_key                             => 'test',
        'indicator.create.name'             => 'xxFoo Bar',
        'indicator.create.formula'          => '5 + $' . $var1,
        'indicator.create.axis_id'          => '1',
        'indicator.create.explanation'      => 'explanation',
        'indicator.create.source'           => 'me',
        'indicator.create.goal_source'      => '@fulano',
        'indicator.create.chart_name'       => 'pie',
        'indicator.create.goal_operator'    => '>=',
        'indicator.create.tags'             => 'you,me,she',
        'indicator.create.visibility_level' => 'public',
        'indicator.create.observations'     => 'lala'
      ],
      ;

    @Iota::TestOnly::Mock::AuthUser::_roles = qw/ _movimento /;

    rest_get '/api/indicator',
      name   => "Listing OK",
      stash  => "list",
      params => [ api_key => 'test' ],
      code   => 200,
      ;

    stash_test 'list' => sub {
        my $inds = shift;

        #is(@{$inds->{indicators}}, 1, 'Roles Movimento ok');
    };

    @Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

    rest_get '/api/indicator',
      name   => "Listing OK",
      stash  => "list",
      params => [ api_key => 'test' ],
      code   => 200,
      ;

    stash_test 'list' => sub {
        my $inds = shift;

        #is(@{$inds->{indicators}}, 2, 'Roles Admin ok');
    };

    @Iota::TestOnly::Mock::AuthUser::_roles = qw/ _prefeitura /;

    rest_get '/api/indicator',
      name   => "Listing OK",
      stash  => "list",
      params => [ api_key => 'test' ],
      code   => 200,
      ;

    stash_test 'list' => sub {
        my $inds = shift;

        #    is( @{ $inds->{indicators} }, 1, 'Roles Prefeitura ok' );
    };
};

done_testing;
