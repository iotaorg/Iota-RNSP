
use strict;
use warnings;

use JSON qw(decode_json);
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Catalyst::Test q(RNSP::PCS);

use HTTP::Request::Common qw /GET POST/;
use URI;
use Package::Stash;

use RNSP::PCS::TestOnly::Mock::AuthUser;
use RNSP::IndicatorChart;

my $schema = RNSP::PCS->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = RNSP::PCS::TestOnly::Mock::AuthUser->new;

$RNSP::PCS::TestOnly::Mock::AuthUser::_id    = 1;
@RNSP::PCS::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

eval {
    $schema->txn_do(
        sub {
            my ( $res, $c );

            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [   api_key                        => 'test',
                    'variable.create.name'         => 'Temperatura semanal',
                    'variable.create.cognomen'     => 'temp_semana',
                    'variable.create.period'       => 'weekly',
                    'variable.create.explanation'  => 'a foo with bar',
                    'variable.create.type'         => 'int',
                ]
            );
            ok( $res->is_success, 'variable created!' );
            my $uri = URI->new( $res->header('Location') . '/value' );

            my $var = eval{decode_json( $res->content )};


            ( $res, $c ) = ctx_request(
                POST '/api/indicator',
                [   api_key                         => 'test',
                    'indicator.create.name'         => 'Temperatura maxima do mes: SP',
                    'indicator.create.formula'      => '$' . $var->{id},
                    'indicator.create.goal'         => '33',
                    'indicator.create.axis_id'      => '2',
                    'indicator.create.explanation'  => 'explanation',
                    'indicator.create.source'       => 'me',
                    'indicator.create.goal_source'  => '@fulano',
                    'indicator.create.chart_name'   => 'pie',
                    'indicator.create.goal_operator'=> '<=',
                    'indicator.create.tags'         => 'you,me,she',

                ]
            );
            ok( $res->is_success, 'indicator created!' );
            my $uri_chart = URI->new( $res->header('Location') . '/chart/period_axis' );
            my $indicator = eval{decode_json( $res->content )};


            my $variable_url = $uri->path_query;

            &add_value($variable_url, '2012-01-01', 23);
            &add_value($variable_url, '2012-02-22', 25);
            &add_value($variable_url, '2012-03-08', 26);
            &add_value($variable_url, '2012-04-12', 28);


            &add_value($variable_url, '2011-01-21', 25);
            &add_value($variable_url, '2011-02-12', 27);
            &add_value($variable_url, '2011-03-25', 27);
            &add_value($variable_url, '2011-04-16', 29);

            &add_value($variable_url, '1192-01-21', 21);
            &add_value($variable_url, '1192-02-12', 22);
            &add_value($variable_url, '1192-03-25', 25);

            my $chart = RNSP::IndicatorChart->new_with_traits(
                schema => $schema,
                indicator => $schema->resultset('Indicator')->find( { id => $indicator->{id} } ),
                traits => ['PeriodAxis'],
                user_id   => $RNSP::PCS::TestOnly::Mock::AuthUser::_id
            );

            my $data = $chart->data();

            ( $res, $c ) = ctx_request(GET $uri_chart->path_query);
            my $obj = eval{decode_json( $res->content )};
            ok($res->is_success, 'GET chart success');
            my @responses = ($data, $obj);
            foreach my $res (@responses){
                is ($res->{goal}, 33, 'goal number ok');
                is ($res->{series}[0]{label}, 'ano 1192', 'Ordem dos anos OK');

                if (is($res->{series}[1]{label}, 'ano 2011', 'segundo ano ok')){
                    my $a2011 = $res->{series}[1];

                    is($a2011->{avg}, '27', 'media correta para 2011');
                    is($a2011->{data}[0][0], '2011-01-21T00:00:00', 'data correta');
                    is($a2011->{data}[0][1], 25, 'valor correto');
                }

                is ($res->{series}[2]{label}, 'ano 2012', '2012 presente');
            }

            ( $res, $c ) = ctx_request(GET $uri_chart->path_query .'?to=2011-12-01&from=2002-01-01&group_by=weekly');
            ok($res->is_success, 'GET chart with params success');
            $obj = eval{decode_json( $res->content )};
            is(scalar @{$obj->{series}}, 4, 'numero de semanas ok');
            is($obj->{series}[0]{avg}, 25, 'media de um numero soh ok!');

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;


sub add_value {
    my ($variable_url, $date, $value) = @_;

    my $req = POST $variable_url, [
        'variable.value.put.value'         => $value,
        'variable.value.put.value_of_date' => $date,
    ];
    $req->method('PUT');
    my ( $res, $c ) = ctx_request($req);
    ok( $res->is_success, 'value ' . $value .  ' on ' . $date . ' created!' );
    my $variable = eval{decode_json( $res->content )};
    return $variable;

}