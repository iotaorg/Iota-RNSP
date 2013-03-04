
use strict;
use warnings;

use JSON qw(from_json);
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Catalyst::Test q(IOTA::PCS);

use HTTP::Request::Common qw /GET POST/;
use URI;
use Package::Stash;

use IOTA::PCS::TestOnly::Mock::AuthUser;

my $schema = IOTA::PCS->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = IOTA::PCS::TestOnly::Mock::AuthUser->new;

$IOTA::PCS::TestOnly::Mock::AuthUser::_id    = 2;
@IOTA::PCS::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

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
                    'indicator.create.formula'      => '$' . $var->{id} . '+ $' . $var2->{id},
                    'indicator.create.goal'         => '33',
                    'indicator.create.axis_id'      => '2',
                    'indicator.create.explanation'  => 'explanation',
                    'indicator.create.source'       => 'me',
                    'indicator.create.goal_source'  => '@fulano',
                    'indicator.create.chart_name'   => 'pie',
                    'indicator.create.goal_operator'=> '<=',
                    'indicator.create.tags'         => 'you,me,she',
                    'indicator.create.indicator_roles' => '_prefeitura,_movimento'
                ]
            );
            ok( $res->is_success, 'indicator created!' );
            my $uri_chart = URI->new( $res->header('Location') . '/variable/value' );
            my $indicator = eval{from_json( $res->content )};

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

            $variable_url = $uri2->path_query;
            ## var 2
            &add_value($variable_url, '2012-01-01', 3);
            &add_value($variable_url, '2012-02-22', 5);
            &add_value($variable_url, '2012-03-08', 6);
            &add_value($variable_url, '2012-04-12', 8);

            &add_value($variable_url, '2011-01-21', 5);
            &add_value($variable_url, '2011-02-12', 7);
            &add_value($variable_url, '2011-03-25', 7);
            &add_value($variable_url, '2011-04-16', 9);

            &add_value($variable_url, '1192-01-21', 1);
            &add_value($variable_url, '1192-02-12', 2);
            &add_value($variable_url, '1192-03-25', 5);


            ( $res, $c ) = ctx_request(GET $uri_chart->path_query);
            my $obj = eval{from_json( $res->content )};

            ok($res->is_success, 'GET values success');

            foreach my $res (@{$obj->{rows}}){
                ok($res->{valid_from}, 'cada valor tem uma data de inicio');
                like($res->{valores}[0]{value}, qr/$res->{valores}[1]{value}$/, 'comeco de uma coluna eh o final da segunda');
            }


            ( $res, $c ) = ctx_request(
                GET '/api/public/user/'.
                    $IOTA::PCS::TestOnly::Mock::AuthUser::_id . '/indicator/' . $indicator->{id} . '/variable/value'
                );
            $obj = eval{from_json( $res->content )};

            ok($res->is_success, 'GET public values success');
            foreach my $res (@{$obj->{rows}}){
                ok($res->{valid_from}, 'cada valor tem uma data de inicio');
                like($res->{valores}[0]{value}, qr/$res->{valores}[1]{value}$/, 'comeco de uma coluna eh o final da segunda');
            }


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