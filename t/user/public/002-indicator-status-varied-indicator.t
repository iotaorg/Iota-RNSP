
use strict;
use warnings;

use JSON qw(from_json);
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Catalyst::Test q(Iota);

use HTTP::Request::Common qw /DELETE GET POST/;
use URI;
use Package::Stash;

use Iota::TestOnly::Mock::AuthUser;

my $schema = Iota->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::TestOnly::Mock::AuthUser->new;

my $seq = 0;
my $indicator;
$Iota::TestOnly::Mock::AuthUser::_id    = 1;
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

use DateTime;

my $last_year = ( DateTime->now()->year() - 1 );

eval {
    $schema->txn_do(
        sub {
            my ( $res, $c );

            my $city = $schema->resultset('City')->create(
                {
                    uf                  => 'XX',
                    name                => 'AWS',
                    telefone_prefeitura => '12345555'
                },
            );

            ( $res, $c ) = ctx_request(
                POST '/api/user',
                [
                    api_key                        => 'test',
                    'user.create.name'             => 'Foo Bar',
                    'user.create.email'            => 'foo@email.com',
                    'user.create.password'         => 'foobarquux1',
                    'user.create.password_confirm' => 'foobarquux1',
                    'user.create.city_id'          => $city->id,
                    'user.create.role'             => 'user',
                    'user.create.network_id'       => 1,
                    'user.create.endereco'         => 'endereco_t'
                ]
            );
            ok( $res->is_success, 'user created' );
            is( $res->code, 201, 'user created' );
            ok( my $new_user = $schema->resultset('User')->find( { email => 'foo@email.com' } ), 'user in DB' );
            is( eval { $new_user->networks->next->id }, 1, 'criado como prefeito' );

            $indicator = &_post(
                201,
                '/api/indicator',
                [
                    api_key                               => 'test',
                    'indicator.create.name'               => 'Divisao modal fake',
                    'indicator.create.formula'            => '#1 + #2',
                    'indicator.create.axis_id'            => '1',
                    'indicator.create.explanation'        => 'fooo',
                    'indicator.create.source'             => 'Rede Nossa São Paulo',
                    'indicator.create.goal_source'        => 'bar',
                    'indicator.create.chart_name'         => 'pie',
                    'indicator.create.goal_operator'      => '>=',
                    'indicator.create.tags'               => 'you,me,she',
                    'indicator.create.observations'       => 'lala',
                    'indicator.create.variety_name'       => 'Faixas',
                    'indicator.create.indicator_type'     => 'varied',
                    'indicator.create.visibility_level'   => 'public',
                    'indicator.create.dynamic_variations' => 1
                ]
            );

            my @variacoes = ();

            push @variacoes,
              &_post(
                201,
                '/api/indicator/' . $indicator->{id} . '/variation',
                [
                    api_key                            => 'test',
                    'indicator.variation.create.name'  => 'Até 1/2 salário mínimo',
                    'indicator.variation.create.order' => '2',
                ]
              );

            push @variacoes,
              &_post(
                201,
                '/api/indicator/' . $indicator->{id} . '/variation',
                [
                    api_key                            => 'test',
                    'indicator.variation.create.name'  => 'Mais de 1/2 a 1 salário mínimo',
                    'indicator.variation.create.order' => '3',
                ]
              );

            push @variacoes,
              &_post(
                201,
                '/api/indicator/' . $indicator->{id} . '/variation',
                [
                    api_key                            => 'test',
                    'indicator.variation.create.name'  => 'Mais de 1 a 2 salários mínimos',
                    'indicator.variation.create.order' => '4',
                ]
              );

            push @variacoes,
              &_post(
                201,
                '/api/indicator/' . $indicator->{id} . '/variation',
                [
                    api_key                            => 'test',
                    'indicator.variation.create.name'  => 'outros',
                    'indicator.variation.create.order' => '5',
                ]
              );

            my $list = &_get( 200, '/api/indicator/' . $indicator->{id} . '/variation' );
            is( @{ $list->{variations} }, 4, 'total match' );

            my @subvar = ();

            push @subvar,
              &_post(
                201,
                '/api/indicator/' . $indicator->{id} . '/variables_variation',
                [
                    api_key                                     => 'test',
                    'indicator.variables_variation.create.name' => 'Pessoas'
                ]
              );

            push @subvar,
              &_post(
                201,
                '/api/indicator/' . $indicator->{id} . '/variables_variation',
                [
                    api_key                                     => 'test',
                    'indicator.variables_variation.create.name' => 'variavel para teste',
                ]
              );

            my $list_variables = &_get( 200, '/api/indicator/variable' );
            is( @{ $list_variables->{variables} }, 2, 'count of /api/indicator/variable looks fine' );

            # -----------
            ## DEADLOCK do formula faz com que a gente tenha que atualizar a formula com os IDs
            # -----------
            $res = &_post(
                202,
                '/api/indicator/' . $indicator->{id},
                [
                    api_key => 'test',

                    'indicator.update.formula' => '#' . $subvar[0]{id} . ' + #' . $subvar[1]{id},
                ]
            );

            my $list_var = &_get( 200, '/api/indicator/' . $indicator->{id} . '/variables_variation' );
            is( @{ $list_var->{variables_variations} }, 2, 'total match' );

            my $detalhes = &_get( 200, '/api/indicator/' . $indicator->{id} );
            is( @{ $detalhes->{variables} },  2, 'detalhes de variaveis ok' );
            is( @{ $detalhes->{variations} }, 4, 'detalhes de variacoes ok' );

            $Iota::TestOnly::Mock::AuthUser::_id = $new_user->id;

            my $zero_status =
              &_get( 200, '/api/public/user/' . $Iota::TestOnly::Mock::AuthUser::_id . '/indicator/status' );
            delete $zero_status->{totals};

            is_deeply(
                $zero_status,
                {
                    status => [
                        {
                            id                  => $indicator->{id},
                            justification_count => undef,
                            without_data        => 1,
                            has_current         => 0,
                            has_data            => 0,
                        }
                    ]
                },
                '$zero_status'
            );

            my @subvals;

            push @subvals,
              &_post(
                201,
                '/api/indicator/' . $indicator->{id} . '/variables_variation/' . $subvar[0]{id} . '/values',
                [
                    api_key                                                   => 'test',
                    'indicator.variation_value.create.value'                  => '5',
                    'indicator.variation_value.create.indicator_variation_id' => $variacoes[0]{id},
                    'indicator.variation_value.create.value_of_date'          => '2010-01-01'
                ]
              );

            $zero_status =
              &_get( 200, '/api/public/user/' . $Iota::TestOnly::Mock::AuthUser::_id . '/indicator/status' );
            delete $zero_status->{totals};

            is_deeply(
                $zero_status,
                {
                    status => [
                        {
                            id                  => $indicator->{id},
                            justification_count => undef,
                            without_data        => 1,
                            has_current         => 0,
                            has_data            => 0,
                        }
                    ]
                },
                '$zero_status continue after inserting only one data'
            );

            my $list_val =
              &_get( 200, '/api/indicator/' . $indicator->{id} . '/variables_variation/' . $subvar[0]{id} . '/values' );

            is( @{ $list_val->{'values'} },      1,   'total match' );
            is( $list_val->{'values'}[0]{value}, '5', 'value match' );
            &_delete( 204,
                    '/api/indicator/'
                  . $indicator->{id}
                  . '/variables_variation/'
                  . $subvar[0]{id}
                  . '/values/'
                  . $list_val->{'values'}[0]{id} );

            # Pessoas
            &_populate( $subvar[0]{id}, \@variacoes, '2010-01-01', qw/3 5 6 10/ );

            my $without_data =
              &_get( 200, '/api/public/user/' . $Iota::TestOnly::Mock::AuthUser::_id . '/indicator/status' );
            delete $without_data->{totals};

            is_deeply(
                $without_data,
                {
                    status => [
                        {
                            id                  => $indicator->{id},
                            justification_count => undef,
                            without_data        => 1,
                            has_current         => 0,
                            has_data            => 0,
                        }
                    ]
                },
                '$without_data: incomplete data'
            );

            # fixo
            &_populate( $subvar[1]{id}, \@variacoes, '2010-01-01', qw/1 1 1 1/ );

            my $has_data =
              &_get( 200, '/api/public/user/' . $Iota::TestOnly::Mock::AuthUser::_id . '/indicator/status' );
            delete $has_data->{totals};

            is_deeply(
                $has_data,
                {
                    status => [
                        {
                            id                  => $indicator->{id},
                            justification_count => undef,
                            without_data        => 0,
                            has_current         => 0,
                            has_data            => 1,
                        }
                    ]
                },
                '$has_data'
            );
            &_populate( $subvar[0]{id}, \@variacoes, $last_year . '-01-01', qw/4 4 1 5/ );

            $has_data = &_get( 200, '/api/public/user/' . $Iota::TestOnly::Mock::AuthUser::_id . '/indicator/status' );
            delete $has_data->{totals};

            is_deeply(
                $has_data,
                {
                    status => [
                        {
                            id                  => $indicator->{id},
                            justification_count => undef,
                            without_data        => 0,
                            has_current         => 0,
                            has_data            => 1,
                        }
                    ]
                },
                '$has_data but current year!'
            );

            &_populate( $subvar[1]{id}, \@variacoes, $last_year . '-01-01', qw/1 1 1 1/ );

            my $has_current =
              &_get( 200, '/api/public/user/' . $Iota::TestOnly::Mock::AuthUser::_id . '/indicator/status' );
            delete $has_current->{totals};

            is_deeply(
                $has_current,
                {
                    status => [
                        {
                            id                  => $indicator->{id},
                            justification_count => undef,
                            without_data        => 0,
                            has_current         => 1,
                            has_data            => 1,
                        }
                    ]
                },
                '$has_current!'
            );

            @variacoes = ();
            push @variacoes,
              &_post(
                201,
                '/api/indicator/' . $indicator->{id} . '/variation',
                [
                    api_key                            => 'test',
                    'indicator.variation.create.name'  => 'mais uma',
                    'indicator.variation.create.order' => '6',
                ]
              );

            $without_data =
              &_get( 200, '/api/public/user/' . $Iota::TestOnly::Mock::AuthUser::_id . '/indicator/status' );
            delete $without_data->{totals};

            is_deeply(
                $without_data,
                {
                    status => [
                        {
                            id                  => $indicator->{id},
                            justification_count => undef,
                            without_data        => 1,
                            has_current         => 0,
                            has_data            => 0,
                        }
                    ]
                },
                '$without_data again because new variation inserted!'
            );

            &_populate( $subvar[0]{id}, \@variacoes, $last_year . '-01-01', 1 );

            $without_data =
              &_get( 200, '/api/public/user/' . $Iota::TestOnly::Mock::AuthUser::_id . '/indicator/status' );
            delete $without_data->{totals};

            is_deeply(
                $without_data,
                {
                    status => [
                        {
                            id                  => $indicator->{id},
                            justification_count => undef,
                            without_data        => 1,
                            has_current         => 0,
                            has_data            => 0,
                        }
                    ]
                },
                '$without_data again because incomplete data'
            );

            &_populate( $subvar[1]{id}, \@variacoes, $last_year . '-01-01', 1 );

            $has_current =
              &_get( 200, '/api/public/user/' . $Iota::TestOnly::Mock::AuthUser::_id . '/indicator/status' );
            delete $has_current->{totals};

            is_deeply(
                $has_current,
                {
                    status => [
                        {
                            id                  => $indicator->{id},
                            justification_count => undef,
                            without_data        => 0,
                            has_current         => 1,
                            has_data            => 1,
                        }
                    ]
                },
                '$has_current now'
            );

            &_populate( $subvar[0]{id}, \@variacoes, '2010-01-01', 1 );
            &_populate( $subvar[1]{id}, \@variacoes, '2010-01-01', 1 );

            $has_data = &_get( 200, '/api/public/user/' . $Iota::TestOnly::Mock::AuthUser::_id . '/indicator/status' );
            delete $has_data->{totals};
            delete $has_data->{justification_count};

            is_deeply(
                $has_data,
                {
                    status => [
                        {
                            id                  => $indicator->{id},
                            justification_count => undef,
                            without_data        => 0,
                            has_current         => 1,
                            has_data            => 1,
                        }
                    ]
                },
                '$has_data now'
            );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;

use JSON qw(from_json);

sub new_var {
    my $type   = shift;
    my $period = shift;
    my ( $res, $c ) = ctx_request(
        POST '/api/variable',
        [
            api_key                       => 'test',
            'variable.create.name'        => 'Foo Bar' . $seq++,
            'variable.create.cognomen'    => 'foobar' . $seq++,
            'variable.create.explanation' => 'a foo with bar' . $seq++,
            'variable.create.type'        => $type,
            'variable.create.period'      => $period || 'week',
            'variable.create.source'      => 'God',
        ]
    );
    if ( $res->code == 201 ) {
        my $xx = eval { from_json( $res->content ) };

        return ( $xx->{id}, URI->new( $res->header('Location') )->as_string );
    }
    else {
        die( 'fail to create new var: ' . $res->code );
    }
}

sub _post {
    my ( $code, $url, $arr ) = @_;
    my ( $res, $c ) = eval { ctx_request( POST $url, $arr ) };
    fail("POST $url => $@") if $@;
    is( $res->code, $code, 'POST ' . $url . ' code is ' . $code );
    my $obj = eval { from_json( $res->content ) };
    fail("JSON $url => $@") if $@;
    ok( $obj->{id}, 'POST ' . $url . ' has id - ID=' . ( $obj->{id} || '' ) );
    return $obj;
}

sub _get {
    my ( $code, $url, $arr ) = @_;
    my ( $res, $c ) = eval { ctx_request( GET $url ) };
    fail("POST $url => $@") if $@;

    if ( $code == 0 || is( $res->code, $code, 'GET ' . $url . ' code is ' . $code ) ) {
        my $obj = eval { from_json( $res->content ) };
        fail("JSON $url => $@") if $@;
        return $obj;
    }
    eval('use DDP;
    p $res;');
    return undef;
}

sub _delete {
    my ( $code, $url, $arr ) = @_;
    my ( $res, $c ) = eval { ctx_request( DELETE $url ) };
    fail("POST $url => $@") if $@;

    if ( $code == 0 || is( $res->code, $code, 'DELETE ' . $url . ' code is ' . $code ) ) {
        if ( $code == 204 ) {
            is( $res->content, '', 'empty body' );
        }
        else {
            my $obj = eval { from_json( $res->content ) };
            fail("JSON $url => $@") if $@;
            return $obj;
        }
    }
    return undef;
}

sub add_value {
    my ( $variable_url, $date, $value ) = @_;

    $variable_url .= '/value';
    my $req = POST $variable_url,
      [
        'variable.value.put.value'         => $value,
        'variable.value.put.value_of_date' => $date,
      ];
    $req->method('PUT');
    my ( $res, $c ) = ctx_request($req);
    ok( $res->is_success, 'value ' . $value . ' on ' . $date . ' created!' );
    my $variable = eval { from_json( $res->content ) };
    return $variable;
}

# _populate($subvar[0]{id}, \@variacoes, '2010-01-01', qw/3 5 6 10/);
sub _populate {
    my ( $variavel, $arr_variacao, $data, @list ) = @_;

    my $i = 0;
    for my $var (@$arr_variacao) {
        my $val = $list[ $i++ ];
        next unless defined $val;
        my $res = &_post(
            201,
            '/api/indicator/' . $indicator->{id} . '/variables_variation/' . $variavel . '/values',
            [
                api_key                                                   => 'test',
                'indicator.variation_value.create.value'                  => $val,
                'indicator.variation_value.create.indicator_variation_id' => $var->{id},
                'indicator.variation_value.create.value_of_date'          => $data
            ]
        );
    }
}

