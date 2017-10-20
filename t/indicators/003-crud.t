use common::sense;
use utf8;

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

    # 003-create.t

    rest_post '/api/indicator',
      name    => "Trying to create indicator without formula",
      stash   => "l1",
      code    => 400,
      is_fail => 1,
      params  => [
        api_key                 => 'test',
        'indicator.create.name' => 'FooBar',
      ],
      ;

    # Adicionado pra testar a falta da fórmula
    stash_test 'l1', sub {
        my $res = shift;
        like( $res->{error}, qr/indicator.create.formula.missi/, 'Formula is Missing' );
    };

    rest_post '/api/axis-dim1',
      name   => "Axis1 Created",
      stash  => "ax1",
      code   => 201,
      params => [
        api_key                        => 'test',
        'axis_dim1.create.name'        => 'gravidas',
        'axis_dim1.create.description' => 'Descr',
      ],
      ;

    rest_post '/api/axis-dim2',
      name   => "Axis2 Created",
      stash  => "ax2",
      code   => 201,
      params => [
        api_key                        => 'test',
        'axis_dim2.create.name'        => '0 a 5',
        'axis_dim2.create.description' => 'Descr',
      ],
      ;

    rest_post '/api/axis-dim3',
      name   => "Axis3 Created",
      stash  => "ax3",
      code   => 201,
      params => [
        api_key                        => 'test',
        'axis_dim3.create.name'        => '1',
        'axis_dim3.create.description' => 'acabar com fome',
      ],
      ;

    rest_post '/api/axis-dim4',
      name   => "Axis4 Created",
      stash  => "ax4",
      code   => 201,
      params => [
        api_key                        => 'test',
        'axis_dim4.create.name'        => '1.1',
        'axis_dim4.create.description' => 'ninguem pasando fome',
      ],
      ;

    my $var1 = &new_var( 'int', 'weekly' );

    rest_post '/api/indicator',
      name   => "Indicator Created",
      stash  => "ind",
      code   => 201,
      params => [
        api_key                          => 'test',
        'indicator.create.name'          => 'Divisão Modal',
        'indicator.create.formula'       => '5 + $' . $var1,
        'indicator.create.axis_id'       => '1',
        'indicator.create.axis_dim1_id'  => stash 'ax1.id',
        'indicator.create.axis_dim2_id'  => stash 'ax2.id',
        'indicator.create.axis_dim3_id'  => stash 'ax3.id',
        'indicator.create.axis_dim4_id'  => stash 'ax4.id',
        'indicator.create.explanation'   => 'explanation',
        'indicator.create.source'        => 'me',
        'indicator.create.goal_source'   => '@fulano',
        'indicator.create.chart_name'    => 'pie',
        'indicator.create.goal_operator' => '>=',
        'indicator.create.tags'          => 'you,me,she',

        'indicator.create.observations'        => 'lala',
        'indicator.create.visibility_level'    => 'restrict',
        'indicator.create.visibility_users_id' => '4',

      ],
      ;

    ok( my $save_test = $schema->resultset('Indicator')->find( stash 'ind.id' ), 'Indicator in DB' );

    # Esse teste não esta no stash_test abaixo porque $save_test será utilizado mais tarde

    stash_test 'ind.get' => sub {

        is( $save_test->name,          'Divisão Modal', 'Name ok' );
        is( $save_test->name_url,      'divisao-modal',  'Name_url ok' );
        is( $save_test->explanation,   'explanation',    'Explanation ok' );
        is( $save_test->source,        'me',             'Source ok' );
        is( $save_test->observations,  'lala',           'Observations ok' );
        is( $save_test->chart_name,    'pie',            'Chart_name ok' );
        is( $save_test->period,        'weekly',         'Period ok' );
        is( $save_test->variable_type, 'int',            'Variable_type ok' );

        is( $save_test->axis_dim1_id, stash 'ax1.id', 'Ax1.id ok' );
        is( $save_test->axis_dim2_id, stash 'ax2.id', 'Ax2.id ok' );

    };

    rest_get stash "ind.url",
      name  => 'Indicator exists',
      stash => 'indica',
      code  => 200,
      ;

    stash_test 'indica' => sub {
        my $indicator_res = shift;

        like( $indicator_res->{period}, qr/weekly/, 'Period of some variable' );

        is( $indicator_res->{visibility_level}, 'restrict', 'Visibility_level ok' );

        is( $indicator_res->{axis_dim1}{name}, 'gravidas', 'Dim1 ok' );
        is( $indicator_res->{axis_dim2}{name}, '0 a 5',    'Dim2 ok' );
        is( $indicator_res->{axis_dim3}{name}, '1',        'Dim3 ok' );
        is( $indicator_res->{axis_dim4}{name}, '1.1',      'Dim4 ok' );

        is_deeply( $indicator_res->{restrict_to_users}, [4], 'Restrict_to_users ok' );
        is( $indicator_res->{name}, 'Divisão Modal', 'Name ok' );

        is( $indicator_res->{formula_human}, '5 + Foo Bar0', 'Formula_human ok' );

    };

    my @variables = $save_test->indicator_variables->all;
    is( $variables[0]->variable_id, $var1, 'Variable saved in table' );

    rest_post '/api/variable/' . $var1,
      name   => "Var Updated",
      stash  => "l2",
      code   => 202,
      params => [
        'variable.update.name'   => 'BarFoo',
        'variable.update.type'   => 'int',
        'variable.update.period' => 'weekly',
        'variable.update.source' => 'Lulu',
      ],
      ;

    $Iota::TestOnly::Mock::AuthUser::_id    = 4;
    @Iota::TestOnly::Mock::AuthUser::_roles = qw/ user /;

    rest_get '/api/indicator',
      name   => "Listing OK",
      stash  => "list",
      params => [ api_key => 'test' ],
      code   => 200,
      ;

    stash_test 'list' => sub {
        my $res = shift;

        is( $res->{indicators}[0]{explanation}, 'explanation', 'Explanation Present!' );

    };

    $Iota::TestOnly::Mock::AuthUser::_id    = 1;
    @Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

    rest_get '/api/log',
      name   => "Listing OK",
      stash  => "list",
      params => [ api_key => 'test' ],
      code   => 200,
      ;

    stash_test 'list' => sub {
        my $res = shift;
        foreach my $log ( @{ $res->{logs} } ) {
            if ( $log->{message} eq 'Adicionou variavel Foo Bar0' ) {
                is( $log->{url}, 'POST /api/variable', 'Log criado com sucesso' );
            }
            elsif ( $log->{message} eq 'Adicionou indicadorFoo Bar' ) {
                is( $log->{url}, 'POST /api/indicator', 'Log do indicador criado com sucesso' );
            }
        }
    };

};

db_transaction {

    # 005-update.t

    rest_post '/api/axis-dim1',
      name   => "Axis Created",
      stash  => "ax1",
      code   => 201,
      params => [
        api_key                        => 'test',
        'axis_dim1.create.name'        => 'gravidas',
        'axis_dim1.create.description' => 'Descr',
      ],
      ;

    rest_post '/api/indicator',
      name   => "Indicator Created",
      stash  => "ind",
      code   => 201,
      params => [
        api_key                             => 'test',
        'indicator.create.name'             => 'Foo Bar',
        'indicator.create.goal'             => '11',
        'indicator.create.formula'          => '5 / 2',
        'indicator.create.axis_id'          => '1',
        'indicator.create.axis_dim1_id'     => stash 'ax1.id',
        'indicator.create.visibility_level' => 'public',
      ],
      ;

    rest_post stash("ind.url"),
      name   => "Indicator Updated",
      stash  => "ind",
      code   => 202,
      params => [
        api_key                 => 'test',
        'indicator.update.goal' => '22',
      ],
      ;

    stash_test "ind" => sub {
        ok( my $updated_indicator = $schema->resultset('Indicator')->find( stash 'ind.id' ), 'Indicator in DB' );

        is( $updated_indicator->name, 'Foo Bar', 'Name not changed!' );
        is( $updated_indicator->goal, '22',      'Goal updated ok' );
    };

    ####################################

    rest_post stash("ind.url"),
      name   => "Indicator Updated",
      stash  => "ind",
      code   => 202,
      params => [
        'indicator.update.goal'               => '23',
        'indicator.update.visibility_level'   => 'private',
        'indicator.update.visibility_user_id' => '4',
      ];

    ok( my $updated_indicator = $schema->resultset('Indicator')->find( stash 'ind.id' ), 'Indicator in DB' );
    is( $updated_indicator->goal,               '23', 'goal updated ok' );
    is( $updated_indicator->visibility_user_id, '4',  'visibility_user_id ok' );

    ####################################

    rest_post stash("ind.url"),
      name   => "Indicator Updated",
      stash  => "ind",
      code   => 202,
      params => [
        'indicator.update.goal'         => '23',
        'indicator.update.axis_dim1_id' => '',
      ];

    do {
        ok( my $local = $schema->resultset('Indicator')->find( stash 'ind.id' ), 'Indicator in DB' );

        is( $local->axis_dim1_id, stash 'ax1.id', 'Keep same dim' );

    };

    # again, but remove dim

    rest_post stash("ind.url"),
      name   => "Indicator Updated",
      stash  => "ind",
      code   => 202,
      params => [
        'indicator.update.goal'         => '23',
        'indicator.update.axis_dim1_id' => '0',
      ],
      ;

    do {
        ok( my $local = $schema->resultset('Indicator')->find( stash 'ind.id' ), 'Indicator in DB' );

        is( $local->axis_dim1_id, undef, 'Removed Dimension' );

    };

    # Fracasso é esperado aqui
    rest_post stash("ind.url"),
      name    => "Indicator Updated",
      stash   => "ind",
      code    => 400,
      is_fail => 1,
      params  => [
        'indicator.update.goal'             => '23',
        'indicator.update.visibility_level' => 'private',
      ],
      ;

    stash_test 'ind' => sub {
        my $res = shift;

        ok( !$res->{is_success}, 'Indicator not updated' );
    };

    rest_post stash("ind.url"),
      name   => "Indicator Updated",
      stash  => "ind",
      code   => 202,
      params => [
        'indicator.update.goal'                   => '25',
        'indicator.update.visibility_level'       => 'network',
        'indicator.update.visibility_networks_id' => '1,2',
      ],
      ;

    ok( my $updated_indicator = $schema->resultset('Indicator')->find( stash 'ind.id' ), 'Indicator in DB' );
    is( $updated_indicator->goal,                                  '25', 'Goal updated ok' );
    is( $updated_indicator->indicator_network_visibilities->count, '2',  'Visibility_networks ok' );

    rest_post stash("ind.url"),
      name   => "Indicator Updated",
      stash  => "ind",
      code   => 202,
      params => [
        'indicator.update.goal'                => '26',
        'indicator.update.visibility_level'    => 'restrict',
        'indicator.update.visibility_users_id' => '4,7',
      ],
      ;

    ok( my $updated_indicator = $schema->resultset('Indicator')->find( stash 'ind.id' ), 'Indicator in DB' );
    is( $updated_indicator->goal, '26', 'Goal updated ok' );
    is_deeply(
        [ sort map { $_->user_id } $updated_indicator->indicator_user_visibilities ],
        [ 4, 7 ],
        'Indicator_user_visibilities ok'
    );
};

# 006-delete.t

db_transaction {

    rest_post '/api/indicator',
      name   => "Interface created - DEL",
      stash  => "del",
      code   => 201,
      params => [
        api_key                             => 'test',
        'indicator.create.name'             => 'Foo Bar',
        'indicator.create.formula'          => '5 + 5',
        'indicator.create.goal'             => '33',
        'indicator.create.axis_id'          => '1',
        'indicator.create.visibility_level' => 'public',
      ],
      ;

    rest_delete stash('del.url'),
      name => "Indecator Deleted",
      code => 204,
      ;

};

done_testing;
