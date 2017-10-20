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

my $uid = $Iota::TestOnly::Mock::AuthUser::_id = 2;
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

    rest_post "/api/user/$uid/indicator",
      name   => "UID/indicator",
      stash  => "uid",
      code   => 201,
      params => [
        api_key                              => 'test',
        'user.indicator.create.goal'         => 'bass down low',
        'user.indicator.create.indicator_id' => stash "ind.id",
        'user.indicator.create.valid_from'   => '2012-11-21',
      ],
      ;

    rest_get stash "uid.url",
      name   => "GET OK!!",
      stash  => "list",
      params => [ api_key => 'test' ],
      code   => 200,
      ;

    stash_test "list" => sub {
        my $dados = shift;

        is( $dados->{goal},         'bass down low', 'Goal ok' );
        is( $dados->{valid_from},   '2012-11-18',    'Start week ok' );
        is( $dados->{valid_from},   '2012-11-18',    'Start week ok' );
        is( $dados->{indicator_id}, stash "ind.id",  'Indicator ok' );
        is( $dados->{justification_of_missing_field} || '', '', 'Empty justification_of_missing_field' );

    };

    rest_post stash "uid.url",
      name   => "Updated OK!!",
      stash  => "uid",
      code   => 202,
      params => [
        api_key                                                => 'test',
        'user.indicator.update.justification_of_missing_field' => 'escape'
      ],
      ;

    rest_get stash "uid.url",
      name   => "GET OK!!",
      stash  => "uri",
      params => [ api_key => 'test' ],
      code   => 200,
      ;

    stash_test "uri" => sub {
        my $dados = shift;

        is( $dados->{justification_of_missing_field}, 'escape', 'justification ok' );
    };

    # ok nova data

    rest_post "/api/user/$uid/indicator",
      name   => "Created com nova data!",
      stash  => "uri",
      code   => 201,
      params => [
        api_key                              => 'test',
        'user.indicator.create.goal'         => 'bass down low',
        'user.indicator.create.indicator_id' => stash "ind.id",
        'user.indicator.create.valid_from'   => '2012-11-25'
      ],
      ;

    # apagar
    rest_delete stash "uid.url",
      name  => "204 / no content!!",
      stash => "uri",
      code  => 204,
      ;

    rest_delete stash "uid.url",
      name    => "404 / not found!!",
      stash   => "uri",
      code    => 404,
      is_fail => 1,
      ;

    # data duplicada

    rest_post "/api/user/$uid/indicator",
      name    => "400 bad request!!",
      stash   => "uri",
      code    => 400,
      is_fail => 1,
      params  => [
        api_key                              => 'test',
        'user.indicator.create.goal'         => 'my world ft giovanca',
        'user.indicator.create.indicator_id' => stash "ind.id",
        'user.indicator.create.valid_from'   => '2012-11-26'
      ],
      ;

    stash_test "uri" => sub {
        my $dados = shift;

        is( $dados->{error}, '{"user.indicator.create.valid_from.invalid":1}', 'campo valid_from invalido' );
    };
};

done_testing;
