
use strict;
use warnings;

use JSON qw(from_json);
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Catalyst::Test q(Iota);

use HTTP::Request::Common qw /GET POST/;
use URI;
use Package::Stash;

use Iota::TestOnly::Mock::AuthUser;
use Iota::IndicatorChart;

my $schema = Iota->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::TestOnly::Mock::AuthUser->new;

$Iota::TestOnly::Mock::AuthUser::_id    = 2;
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

eval {
    $schema->txn_do(
        sub {
            my ( $res, $c );

            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [
                    api_key                       => 'test',
                    'variable.create.name'        => 'Temperatura semanal',
                    'variable.create.cognomen'    => 'temp_semana',
                    'variable.create.period'      => 'weekly',
                    'variable.create.explanation' => 'a foo with bar',
                    'variable.create.type'        => 'int',
                ]
            );
            ok( $res->is_success, 'variable created!' );
            my $uri = URI->new( $res->header('Location') . '/value' );

            my $var = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [
                    api_key                       => 'test',
                    'variable.create.name'        => 'Temperatura semanal 2',
                    'variable.create.cognomen'    => 'temp_semana2',
                    'variable.create.period'      => 'weekly',
                    'variable.create.explanation' => 'a foo with bar',
                    'variable.create.type'        => 'int',
                ]
            );
            ok( $res->is_success, 'variable created!' );
            my $uri2 = URI->new( $res->header('Location') . '/value' );

            my $var2 = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request(
                POST '/api/indicator',
                [
                    api_key                             => 'test',
                    'indicator.create.name'             => 'Temperatura maxima do mes: SP',
                    'indicator.create.formula'          => '$' . $var->{id} . ' + $' . $var2->{id},
                    'indicator.create.goal'             => '33',
                    'indicator.create.axis_id'          => '2',
                    'indicator.create.explanation'      => 'explanation',
                    'indicator.create.source'           => 'me',
                    'indicator.create.goal_source'      => '@fulano',
                    'indicator.create.chart_name'       => 'pie',
                    'indicator.create.goal_operator'    => '<=',
                    'indicator.create.tags'             => 'you,me,she',
                    'indicator.create.visibility_level' => 'public',

                ]
            );
            ok( $res->is_success, 'indicator created!' );
            my $uri_chart = URI->new( $res->header('Location') . '/chart/period_axis' );
            my $indicator = eval { from_json( $res->content ) };

            my $variable_url = $uri->path_query;

            &add_value( $variable_url, '2012-02-01', 23 );
            &add_value( $variable_url, '2012-03-22', 25 );
            &add_value( $variable_url, '2012-04-08', 26 );
            &add_value( $variable_url, '2012-05-12', 28 );

            &add_value( $variable_url, '2011-02-21', 25 );
            &add_value( $variable_url, '2011-03-12', 27 );
            &add_value( $variable_url, '2011-04-25', 27 );
            &add_value( $variable_url, '2011-05-16', 29 );

            &add_value( $variable_url, '1192-02-21', 21 );
            &add_value( $variable_url, '1192-03-12', 22 );
            &add_value( $variable_url, '1192-04-25', 25 );

            $variable_url = $uri2->path_query;

            &add_value( $variable_url, '2012-02-01', 3 );
            &add_value( $variable_url, '2012-03-22', 5 );
            &add_value( $variable_url, '2012-04-08', 6 );
            &add_value( $variable_url, '2012-05-12', 8 );

            &add_value( $variable_url, '2011-02-21', 5 );
            &add_value( $variable_url, '2011-03-12', 7 );
            &add_value( $variable_url, '2011-04-25', 7 );
            &add_value( $variable_url, '2011-05-16', 9 );

            &add_value( $variable_url, '1192-02-21', 1 );
            &add_value( $variable_url, '1192-03-12', 2 );
            &add_value( $variable_url, '1192-04-25', 5 );

            my $chart = Iota::IndicatorChart->new_with_traits(
                schema    => $schema,
                indicator => $schema->resultset('Indicator')->find( { id => $indicator->{id} } ),
                traits    => ['PeriodAxis'],

            );

            my $data = $chart->data(
                group_by => 'yearly',
                user_id  => $Iota::TestOnly::Mock::AuthUser::_id,
            );

            ( $res, $c ) = ctx_request( GET $uri_chart->path_query . '?group_by=yearly' );

            my $obj = eval { from_json( $res->content ) };
            ok( $res->is_success, 'GET chart success' );

            ( $res, $c ) =
              ctx_request( GET '/api/public/user/'
                  . $Iota::TestOnly::Mock::AuthUser::_id
                  . '/indicator/'
                  . $indicator->{id}
                  . '/chart/period_axis?group_by=yearly' );
            my $obj_public = eval { from_json( $res->content ) };
            ok( $res->is_success, 'GET chart public success' );

            my @responses = ( $data, $obj, $obj_public );
            foreach my $res (@responses) {
                is( $res->{goal},             33,     'goal number ok' );
                is( $res->{series}[0]{label}, '1192', 'Ordem dos anos OK' );

                if ( is( $res->{series}[1]{label}, '2011', 'segundo ano ok' ) ) {
                    my $a2011 = $res->{series}[1];

                    is( $a2011->{avg},        '34',                  'media correta para 2011' );
                    is( $a2011->{data}[0][0], '2011-02-20T00:00:00', 'data correta' );
                    is( $a2011->{data}[0][1], 25 + 5,                'valor correto' );
                }

                is( $res->{series}[2]{label}, '2012', '2012 presente' );
            }

            ( $res, $c ) = ctx_request( GET $uri_chart->path_query . '?to=2011-12-01&from=2002-01-01&group_by=weekly' );
            ok( $res->is_success, 'GET chart with params success' );
            $obj = eval { from_json( $res->content ) };
            is( scalar @{ $obj->{series} }, 4,  'numero de semanas ok' );
            is( $obj->{series}[0]{avg},     30, 'media de um numero soh ok!' );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;

sub add_value {
    my ( $variable_url, $date, $value ) = @_;

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
