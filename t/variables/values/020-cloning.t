
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../lib";
use JSON;

use Catalyst::Test q(Iota);

use HTTP::Request::Common qw /GET POST DELETE/;
use Package::Stash;

use Iota::TestOnly::Mock::AuthUser;

my $stash = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user  = Iota::TestOnly::Mock::AuthUser->new;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

my $schema = Iota->model('DB');

my $values_ids = {};
my $indicator;

# test copia de prefeitura para movimento
my $pref = 4;
my $mov  = 5;

eval {
    $schema->txn_do(
        sub {

            $Iota::TestOnly::Mock::AuthUser::_id    = 1;
            @Iota::TestOnly::Mock::AuthUser::_roles = qw/ superadmin /;

            &add_indicator();

            @Iota::TestOnly::Mock::AuthUser::_roles = qw/ user /;

            &add_value( '2010', 19, $pref, 1 );
            &add_value( '2010', 20, $pref, 1 );

            &check_value( '2010', $pref, 2 );

            &add_value( '2011', 20, $pref, 1 );

            &add_value( '2011', 20, $mov, 0 );

            &value_not_exists( '2011', 19, $mov, $pref );
            &value_not_exists( '2012', 20, $mov, $pref );

            my $list = &list_status();

            ok( delete $list->{variables_names}{19} );
            ok( delete $list->{variables_names}{20} );
            ok( delete $list->{variables_names} );
            is_deeply(
                $list,
                {
                    checkbox => {
                        19 => {
                            '2010-01-01' => 1
                        },
                        20 => {
                            '2010-01-01' => 1,
                            '2011-01-01' => 0
                        }
                    },
                    periods => [ '2010-01-01', '2011-01-01', ]
                },
                'checkbox status looks good!'
            );

            my $x2010 = &post_2010();
            is( $x2010->{number_of_clones}, 2, '2 clones' );

            &check_value( '2010', $mov, 2 );

            # check if the value is the same
            # check if the values from the copy already exists
            &is_same_value( '2010', 19, $pref, 1 );
            &is_same_value( '2010', 20, $pref, 1 );

            &is_same_value( '2011', 20, $pref, 1 );

            # and then check if non-"should"-modify is the same
            &is_same_value( '2011', 20, $mov, 0 );

            # and there's new values for 2010!
            &is_same_value( '2010', 19, $mov, 1, $pref );

            # and the replaced-one.
            &is_same_value( '2010', 20, $mov, 1, $pref );

            my $x2011 = &post_2011();
            is( $x2011->{number_of_clones}, 1, '1 clones' );

            &value_not_exists( '2011', 19, $mov, $pref );
            &is_same_value( '2011', 20, $mov, 1, $pref );

            $list = &list_status();

            ok( delete $list->{variables_names}{19} );
            ok( delete $list->{variables_names}{20} );
            ok( delete $list->{variables_names} );
            is_deeply(
                $list,
                {
                    checkbox => {
                        19 => {
                            '2010-01-01' => 0
                        },
                        20 => {
                            '2010-01-01' => 0,
                            '2011-01-01' => 0
                        }
                    },
                    periods => [ '2010-01-01', '2011-01-01', ]
                },
                'checkbox status looks good 3!'
            );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;

sub add_value {
    my ( $ano, $va, $user, $val ) = @_;

    $Iota::TestOnly::Mock::AuthUser::_id = $user;

    my ( $res, $c ) = ctx_request(
        POST "/api/variable/$va/value",
        [
            'variable.value.create.value'         => $val,
            'variable.value.create.value_of_date' => $ano . '-01-01 14:22:44',
        ]
    );
    is( $res->code, 201, 'value for variable ' . $va . ' created [' . $ano . '] user ' . $user );

    my $obj = eval { from_json( $res->content ) };
    $values_ids->{$va}{$user}{$ano} = $obj->{id};
}

sub list_status {

    # quem ta logado é o movimento
    $Iota::TestOnly::Mock::AuthUser::_id = $mov;

    my ( $res, $c ) = ctx_request( GET "/api/user/$mov/clone_variable?variables=20,19,18&institute_id=1" );

    my $obj = eval { from_json( $res->content ) };
    return $obj;

}

sub post_2010 {
    my ( $ano, $va ) = @_;

    my ( $res, $c ) = ctx_request(
        POST "/api/user/$mov/clone_variable",
        [
            'period1'       => '2010-01-01',
            'variable:19_1' => '1',
            'variable:20_3' => '1',
            'institute_id'  => 1
        ]
    );
    is( $res->code, 400, 'invalid input.' );

    ( $res, $c ) = ctx_request( POST "/api/user/$mov/clone_variable", [ 'institute_id' => 2 ] );
    is( $res->code, 400, 'invalid input.' );

    ( $res, $c ) = ctx_request(
        POST "/api/user/$mov/clone_variable",
        [
            'period1'      => '2010-01-01',
            'institute_id' => 1
        ]
    );
    is( $res->code, 400, 'invalid input.' );

    ( $res, $c ) = ctx_request(
        POST "/api/user/$mov/clone_variable",
        [
            'period1'       => '2010-01-01',
            'variable:19_1' => '1',
            'variable:20_1' => '1',
            'institute_id'  => 1
        ]
    );

    is( $res->code, 200, 'values created successfully' );
    my $obj = eval { from_json( $res->content ) };
    return $obj;
}

sub post_2011 {
    my ( $ano, $va ) = @_;

    my ( $res, $c ) = ctx_request(
        POST "/api/user/$mov/clone_variable",
        [
            'period1'       => '2011-01-01',
            'variable:19_1' => '1',
            'variable:20_1' => '1',
            'institute_id'  => 1
        ]
    );

    is( $res->code, 200, 'values created successfully' );
    my $obj = eval { from_json( $res->content ) };
    return $obj;
}

sub is_same_value {

    my ( $ano, $va, $user, $val, $check_clone ) = @_;

    my $row = $schema->resultset('VariableValue')->search(
        {
            valid_from  => $ano . '-01-01',
            user_id     => $user,
            variable_id => $va
        }
    )->next;
    ok( $row, 'found in db' );
    is( $row->value, $val, 'variable have the correct value' );
    is( $row->cloned_from_user->id, $check_clone, 'is $cloned_from_user ok' ) if $check_clone;
}

sub value_not_exists {

    my ( $ano, $va, $user, $user2 ) = @_;

    my $row = $schema->resultset('VariableValue')->search(
        {
            valid_from  => $ano . '-01-01',
            user_id     => $user,
            variable_id => $va
        }
    )->next;
    ok( !$row, 'not found in db' );

    my $row2 = $schema->resultset('VariableValue')->search(
        {
            valid_from  => $ano . '-01-01',
            user_id     => $user2,
            variable_id => $va
        }
    )->next;
    ok( !$row2, 'not found in db' );

}

sub add_indicator {

    my ( $res, $c ) = ctx_request(
        POST '/api/indicator',
        [
            api_key                          => 'test',
            'indicator.create.name'          => 'Foo Bar',
            'indicator.create.formula'       => '$19+$20',
            'indicator.create.axis_id'       => '1',
            'indicator.create.explanation'   => 'explanation',
            'indicator.create.source'        => 'me',
            'indicator.create.goal_source'   => '@fulano',
            'indicator.create.chart_name'    => 'pie',
            'indicator.create.goal_operator' => '>=',
            'indicator.create.tags'          => 'you,me,she',

            'indicator.create.observations'     => 'lala',
            'indicator.create.visibility_level' => 'public',

        ]
    );

    ok( $res->is_success, 'indicator created!' );
    is( $res->code, 201, 'created!' );

    $indicator = eval { from_json( $res->content ) };
}

sub check_value {
    my ( $ano, $user, $valor ) = @_;

    my $row = $schema->resultset('IndicatorValue')->search(
        {
            valid_from => $ano . '-01-01',
            user_id    => $user
        }
    )->next;
    ok( $row, 'IndicatorValue found in db' );
    is( $row->value, $valor, 'indicator have the correct value' ) if $row;

}
