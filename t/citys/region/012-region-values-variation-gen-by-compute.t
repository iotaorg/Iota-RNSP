
use strict;
use warnings;
use URI;
use Test::More;
use JSON qw(from_json);

use FindBin qw($Bin);
use lib "$Bin/../../lib";

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
my $indicator;
my $seq = 0;

eval {
    $schema->txn_do(
        sub {

            my $inst = $schema->resultset('Institute')->create(
                {
                    active_me_when_empty => 1,
                    name                 => 'name',
                    short_name           => 'short_name',

                }
            );
            my $net = $schema->resultset('Network')->create(
                {
                    name         => 'name',
                    name_url     => 'short_name',
                    domain_name  => 'domain_name',
                    created_by   => 1,
                    institute_id => $inst->id,
                }
            );

            my $u = $schema->resultset('User')->create(
                {
                    name            => 'name',
                    email           => 'email@email.com',
                    institute_id    => $inst->id,
                    password        => '!!!',
                    regions_enabled => 1
                }
            );
            $u->add_to_user_roles( { role => { name => 'admin' } } );
            $u->add_to_network_users( { network_id => $net->id } );

            $ENV{HARNESS_ACTIVE_institute_id} = $inst->id;

            $Iota::TestOnly::Mock::AuthUser::_id = $u->id;

            my ( $res, $c );
            ( $res, $c ) = ctx_request(
                POST '/api/city',
                [
                    api_key            => 'test',
                    'city.create.name' => 'FooBar',

                ]
            );
            ok( !$res->is_success, 'invalid request' );
            is( $res->code, 400, 'invalid request' );

            ( $res, $c ) = ctx_request(
                POST '/api/city',
                [
                    api_key                 => 'test',
                    'city.create.name'      => 'Foo Bar',
                    'city.create.state_id'  => 1,
                    'city.create.latitude'  => 5666.55,
                    'city.create.longitude' => 1000.11,
                ]
            );
            ok( $res->is_success, 'city created!' );
            is( $res->code, 201, 'created!' );

            my $city_uri = $res->header('Location');
            ( $res, $c ) = ctx_request(
                POST $city_uri . '/region',
                [
                    api_key                                     => 'test',
                    'city.region.create.name'                   => 'a region',
                    'city.region.create.description'            => 'with no description',
                    'city.region.create.subregions_valid_after' => '2010-01-01',
                ]
            );

            ok( $res->is_success, 'region created!' );
            is( $res->code, 201, 'region created!' );

            my $reg0_uri = $res->header('Location');
            my $reg0 = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request(
                POST $city_uri . '/region',
                [
                    api_key                           => 'test',
                    'city.region.create.name'         => 'second region',
                    'city.region.create.upper_region' => $reg0->{id},
                    'city.region.create.description'  => 'with Description',
                ]
            );

            ok( $res->is_success, 'region created!' );
            is( $res->code, 201, 'region created!' );

            my $reg1_uri = $res->header('Location');
            my $reg1 = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request( GET $reg1_uri );
            my $obj = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [
                    api_key                       => 'test',
                    'variable.create.name'        => 'Foo Bar',
                    'variable.create.cognomen'    => 'foobar',
                    'variable.create.period'      => 'weekly',
                    'variable.create.explanation' => 'a foo with bar',
                    'variable.create.type'        => 'int',
                ]
            );
            ok( $res->is_success, 'variable created!' );
            is( $res->code, 201, 'created!' );

            &update_region_valid_time( $reg0, '1931-01-01' );

            my ( $var1, $uri1 ) = &new_var( 'int', 'yearly' );

            $indicator = &_post(
                201,
                '/api/indicator',
                [
                    api_key                    => 'test',
                    'indicator.create.name'    => 'Distribuição de renda',
                    'indicator.create.formula' => '#1 + #2 + $' . $var1,
                    'indicator.create.axis_id' => '1',
                    'indicator.create.explanation' =>
                      'Distribuição por faixas de renda (pessoas de 10 anos ou mais de idade).',
                    'indicator.create.source' => 'Rede Nossa São Paulo',
                    'indicator.create.goal_source' =>
                      'Diminuir as distâncias entre as faixas de renda da população.',
                    'indicator.create.chart_name'       => 'pie',
                    'indicator.create.goal_operator'    => '>=',
                    'indicator.create.tags'             => 'you,me,she',
                    'indicator.create.observations'     => 'lala',
                    'indicator.create.variety_name'     => 'Faixas',
                    'indicator.create.indicator_type'   => 'varied',
                    'indicator.create.visibility_level' => 'public',

                ]
            );

            my @variacoes = ();

            push @variacoes,
              &_post(
                201,
                '/api/indicator/' . $indicator->{id} . '/variation',
                [
                    api_key                            => 'test',
                    'indicator.variation.create.name'  => 'faixa0',
                    'indicator.variation.create.order' => '2',
                ]
              );

            push @variacoes,
              &_post(
                201,
                '/api/indicator/' . $indicator->{id} . '/variation',
                [
                    api_key                            => 'test',
                    'indicator.variation.create.name'  => 'faixa1',
                    'indicator.variation.create.order' => '3',
                ]
              );

            my $list = &_get( 200, '/api/indicator/' . $indicator->{id} . '/variation' );
            is( @{ $list->{variations} }, 2, 'total match' );

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

                    'indicator.update.formula' => '#' . $subvar[0]{id} . ' + #' . $subvar[1]{id} . ' + $' . $var1,
                ]
            );

            # Pessoas
            &_populate( $reg1->{id}, $subvar[0]{id}, \@variacoes, '2010-01-01', qw/3 5/ );

            &_populate( $reg1->{id}, $subvar[0]{id}, \@variacoes, '1992-01-01', qw/8 9/ );

            # fixo
            &_populate( $reg1->{id}, $subvar[1]{id}, \@variacoes, '2010-01-01', qw/1 1 / );

            my @rows = $schema->resultset('IndicatorValue')->all;
            is( scalar @rows, 0, 'sem linhas, pois os dados estao incompletos' );

            &add_value( $reg1_uri, $var1, '2010-01-01', 15 );
            @rows = $schema->resultset('IndicatorValue')->search( undef, { order_by => 'id' } )->all;

            is( scalar @rows, 4, 'quatro linhas, pois agora temos os dados (regian upper calculada sozinho)' );
            is( $rows[0]->variation_name, 'faixa0', 'faixa ok' );
            is( $rows[0]->value,          '19',     'valor ok' );
            is( $rows[0]->region_id,      $reg1->{id} );

            #is( $rows[0]->generated_by_compute, 0 );

            is( $rows[1]->variation_name, 'faixa1', 'faixa ok' );
            is( $rows[1]->value,          '21',     'valor ok' );

            is( $rows[1]->region_id, $reg1->{id} );

            #is( $rows[1]->generated_by_compute, 0 );

            is( $rows[2]->region_id, $reg0->{id} );

            #is( $rows[2]->generated_by_compute, 1 );

            is( $rows[3]->region_id, $reg0->{id} );

            #is( $rows[3]->generated_by_compute, 1 );

            my $period = &_get( 200,
                    '/api/indicator/'
                  . $indicator->{id}
                  . '/variables_variation/'
                  . $subvar[0]{id}
                  . '/values?valid_from=2010-01-01' );
            is( @{ $period->{values} }, 0, 'nenhum resultado sem regiao' );

            $period = &_get( 200,
                    '/api/indicator/'
                  . $indicator->{id}
                  . '/variables_variation/'
                  . $subvar[0]{id}
                  . '/values?valid_from=2010-01-01&region_id='
                  . $reg1->{id} );

            is( @{ $period->{values} }, 2, 'nenhum resultado sem regiao' );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
use JSON qw(from_json);

sub update_region_valid_time {

    $schema->resultset('Region')->find(
        {
            id => shift->{id}
        }
      )->update(
        {
            subregions_valid_after => shift
        }
      );

}

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
    my ( $region_url, $variable, $date, $value ) = @_;

    $region_url .= '/value';
    my $req = POST $region_url, [
        'region.variable.value.put.value'         => $value,
        'region.variable.value.put.variable_id'   => $variable,
        'region.variable.value.put.value_of_date' => $date,

    ];
    $req->method('PUT');
    my ( $res, $c ) = ctx_request($req);
    ok( $res->is_success, 'value ' . $value . ' on ' . $date . ' created!' );
    $variable = eval { from_json( $res->content ) };
    return $variable;
}

# _populate($subvar[0]{id}, \@variacoes, '2010-01-01', qw/3 5 6 10/);
sub _populate {
    my ( $region_id, $variavel, $arr_variacao, $data, @list ) = @_;

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
                'indicator.variation_value.create.value_of_date'          => $data,
                'indicator.variation_value.create.region_id'              => $region_id,

            ]
        );
    }
}
