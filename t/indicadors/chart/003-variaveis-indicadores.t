
use strict;
use warnings;

use JSON qw(from_json);
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Catalyst::Test q(RNSP::PCS);

use HTTP::Request::Common qw /GET POST/;
use URI;
use Package::Stash;

use RNSP::PCS::TestOnly::Mock::AuthUser;

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
                    'variable.create.name'         => 'XXXX',
                    'variable.create.cognomen'     => 'XXXAA',
                    'variable.create.period'       => 'weekly',
                    'variable.create.explanation'  => 'a foo with bar',
                    'variable.create.type'         => 'int',
                ]
            );
            ok( $res->is_success, 'variable created!' );
            my $uri0 = URI->new( $res->header('Location') . '/value' );
            my $var0 = eval{from_json( $res->content )};

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
            my $var = eval{from_json( $res->content )};


            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [   api_key                        => 'test',
                    'variable.create.name'         => 'nostradamus',
                    'variable.create.cognomen'     => 'nostradamus',
                    'variable.create.period'       => 'weekly',
                    'variable.create.explanation'  => 'nostradamus end of world',
                    'variable.create.type'         => 'int',
                ]
            );
            ok( $res->is_success, 'variable created!' );
            my $uri2 = URI->new( $res->header('Location') . '/value' );
            my $var2 = eval{from_json( $res->content )};


            ( $res, $c ) = ctx_request(
                POST '/api/indicator',
                [   api_key                         => 'test',
                    'indicator.create.name'         => 'Temperatura maxima do mes: SP',
                    'indicator.create.formula'      => '$' . $var->{id} . '+ $' . $var2->{id} . ' - $' . $var0->{id},
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
            my $indicator = eval{from_json( $res->content )};

            my $variable_url = $uri->path_query;

            &add_value($variable_url, '2012-01-05', 23);


            $variable_url = $uri2->path_query;
            ## var 2
            &add_value($variable_url, '2012-01-04', 3);


            $variable_url = $uri0->path_query;
            my $path = $res->header('Location');
            my $uri_chart = URI->new( $path . '/variable/period/2012-01-01' );
            ( $res, $c ) = ctx_request(GET $uri_chart->path_query);
            my $obj = eval{from_json( $res->content )};
            is(@{$obj->{rows}}, 3, 'count ok');
            ok($res->is_success, 'GET chart success');

            foreach my $res (@{$obj->{rows}}){
                ok($res->{id}, 'variavel com id');

                if ($res->{id} == $var->{id}){
                    is($res->{value}, '23', 'variavel 1 com valor ok');
                }
            }

            $uri_chart = URI->new( $path . '/variable/period/2018-01-01' );
            ( $res, $c ) = ctx_request(GET $uri_chart->path_query);

            $obj = eval{from_json( $res->content )};

            is(@{$obj->{rows}}, 3, 'count ok');

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
    my $variable = eval{from_json( $res->content )};
    return $variable;

}