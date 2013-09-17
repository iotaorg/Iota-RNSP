
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
                    'variable.create.name'        => 'XXXX',
                    'variable.create.cognomen'    => 'XXXAA',
                    'variable.create.period'      => 'weekly',
                    'variable.create.explanation' => 'a foo with bar',
                    'variable.create.type'        => 'int',

                ]
            );
            ok( $res->is_success, 'variable created!' );
            my $uri0 = URI->new( $res->header('Location') . '/value' );
            my $var0 = eval { from_json( $res->content ) };

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
                    'variable.create.name'        => 'nostradamus',
                    'variable.create.cognomen'    => 'nostradamus',
                    'variable.create.period'      => 'weekly',
                    'variable.create.explanation' => 'nostradamus end of world',
                    'variable.create.type'        => 'int',
                ]
            );
            ok( $res->is_success, 'variable created!' );



            my $uri2 = URI->new( $res->header('Location') . '/value' );
            my $var2 = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request(
                POST '/api/indicator',
                [
                    api_key                          => 'test',
                    'indicator.create.name'          => 'Temperatura maxima do mes: SP',
                    'indicator.create.formula'       => '$' . $var->{id} . '+ $' . $var2->{id} . ' - $' . $var0->{id},
                    'indicator.create.goal'          => '33',
                    'indicator.create.axis_id'       => '2',
                    'indicator.create.explanation'   => 'explanation',
                    'indicator.create.source'        => 'me',
                    'indicator.create.goal_source'   => '@fulano',
                    'indicator.create.chart_name'    => 'pie',
                    'indicator.create.goal_operator' => '<=',
                    'indicator.create.tags'          => 'you,me,she',
                    'indicator.create.visibility_level' => 'public',

                ]
            );
            ok( $res->is_success, 'indicator created!' );
            my $indicator = eval { from_json( $res->content ) };



            $Iota::TestOnly::Mock::AuthUser::_id    = 4;
            @Iota::TestOnly::Mock::AuthUser::_roles = qw/ user /;


            my $variable_url = $uri->path_query;

            &add_value( $variable_url, '2012-01-05', 23 );

            $variable_url = $uri2->path_query;
            ## var 2
            &add_value( $variable_url, '2012-01-04', 3 );

            $variable_url = $uri0->path_query;
            my $path      = $res->header('Location');
            my $uri_chart = URI->new( $path . '/variable/period/2012-01-01' );
            ( $res, $c ) = ctx_request( GET $uri_chart->path_query );
            my $obj = eval { from_json( $res->content ) };
            is( @{ $obj->{rows} }, 3, 'count ok' );
            ok( $res->is_success, 'GET chart success' );

            foreach my $res ( @{ $obj->{rows} } ) {
                ok( $res->{id}, 'variavel com id' );

                if ( $res->{id} == $var->{id} ) {
                    is( $res->{value}, '23', 'variavel 1 com valor ok' );
                }
            }

            $uri_chart = URI->new( $path . '/variable/period/2018-01-01' );
            ( $res, $c ) = ctx_request( GET $uri_chart->path_query );

            $obj = eval { from_json( $res->content ) };

            is( @{ $obj->{rows} }, 3, 'count ok' );

            $Iota::TestOnly::Mock::AuthUser::_id    = 2;
            @Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin/;

            ( $res, $c ) = ctx_request(
                POST '/api/indicator',
                [
                    api_key                             => 'test',
                    'indicator.create.name'             => 'Temperatura minima do mes: SP',
                    'indicator.create.formula'          => '$' . $var->{id},
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
            $indicator = eval { from_json( $res->content ) };


            $Iota::TestOnly::Mock::AuthUser::_id    = 4;
            @Iota::TestOnly::Mock::AuthUser::_roles = qw/ user /;



            ( $res, $c ) = ctx_request( GET '/download-indicators?user_id=4' );
            ok( $res->is_success, 'get is ok' );

            $obj = eval { from_json( $res->content ) };
            is( @{ $obj->{data} }, 1, "Download by user." );

            ( $res, $c ) = ctx_request( GET '/download-indicators?user_id=1' );
            ok( $res->is_success, 'get is ok' );

            $obj = eval { from_json( $res->content ) };
            is( @{ $obj->{data} }, 0, "Inverse test Download by user." );

            ( $res, $c ) = ctx_request( GET '/download-indicators?valid_from=2012-01-01' );
            ok( $res->is_success, 'get is ok' );

            $obj = eval { from_json( $res->content ) };

            is( @{ $obj->{data} }, 1, "Download by single date." );

            ( $res, $c ) = ctx_request( GET '/download-indicators?valid_from=2010-01-15' );
            ok( $res->is_success, 'get is ok' );

            $obj = eval { from_json( $res->content ) };

            is( @{ $obj->{data} }, 0, "Inverse test Download by single date." );

            ( $res, $c ) = ctx_request( GET '/download-indicators?valid_from_begin=2012-01-01' );
            ok( $res->is_success, 'get is ok' );

            $obj = eval { from_json( $res->content ) };

            is( @{ $obj->{data} }, 1, "Download by begining date." );

            ( $res, $c ) = ctx_request( GET '/download-indicators?valid_from_begin=2012-01-15' );
            ok( $res->is_success, 'get is ok' );

            $obj = eval { from_json( $res->content ) };

            is( @{ $obj->{data} }, 0, "Inverse test  Download by begining date." );

            ( $res, $c ) = ctx_request( GET '/download-indicators?valid_from_end=2012-01-01' );
            ok( $res->is_success, 'get is ok' );

            $obj = eval { from_json( $res->content ) };

            is( @{ $obj->{data} }, 1, "Download by ending date." );

            ( $res, $c ) = ctx_request( GET '/download-indicators?valid_from_end=2010-01-15' );
            ok( $res->is_success, 'get is ok' );

            $obj = eval { from_json( $res->content ) };

            is( @{ $obj->{data} }, 0, "Inverse test  Download by ending date." );

            ( $res, $c ) = ctx_request( GET '/download-indicators?indicator_id=' . $indicator->{id} );
            ok( $res->is_success, 'get is ok' );

            $obj = eval { from_json( $res->content ) };

            is( @{ $obj->{data} }, 1, "Download by indicator." );

            ( $res, $c ) = ctx_request( GET '/download-indicators?indicator_id=1' );
            ok( $res->is_success, 'get is ok' );

            $obj = eval { from_json( $res->content ) };

            is( @{ $obj->{data} }, 0, "Inverse test Download by indicator." );

            ( $res, $c ) = ctx_request(
                GET '/download-indicators?user_id=4&valid_from=2012-01-01&indicator_id=' . $indicator->{id} );

            ok( $res->is_success, 'get is ok' );

            $obj = eval { from_json( $res->content ) };

            is( @{ $obj->{data} }, 1, "Download by all parameters combined and a single date." );

            ( $res, $c ) = ctx_request( GET '/download-indicators?user_id=1&valid_from=2012-01-15&indicator_id=1' );

            ok( $res->is_success, 'get is ok' );

            $obj = eval { from_json( $res->content ) };

            is( @{ $obj->{data} }, 0, "Inverse test Download by all parameters combined and a single date." );

            ( $res, $c ) = ctx_request(
                GET '/download-indicators?user_id=4&valid_from_begin=2012-01-01&valid_from_end=2014-01-01&indicator_id='
                  . $indicator->{id} );

            ok( $res->is_success, 'get is ok' );

            $obj = eval { from_json( $res->content ) };

            is( @{ $obj->{data} }, 1, "Download by all parameters combined in a date range." );

            ( $res, $c ) =
              ctx_request( GET
                  '/download-indicators?user_id=1&valid_from_begin=2012-01-15&valid_from_end=2014-01-15&indicator_id=1'
              );

            ok( $res->is_success, 'get is ok' );

            $obj = eval { from_json( $res->content ) };

            is( @{ $obj->{data} }, 0, "Inverse test Download by all parameters combined in a date range." );

             ($res, $c) = ctx_request(GET '/download-variables?user_id=4');
            ok( $res->is_success, 'get is ok' );

            $obj = eval { from_json ( $res->content ) };
            is( @{ $obj->{data} }, 2, "Download variables by user.");

            ($res, $c) = ctx_request(GET '/download-variables?valid_from=2012-01-01');
            ok( $res->is_success, 'get is ok' );

            $obj = eval { from_json ( $res->content ) };

            is( @{ $obj->{data} }, 2, "Download variables by single date.");

            ($res, $c) = ctx_request(GET '/download-variables?valid_from_begin=2012-01-01');
            ok( $res->is_success, 'get is ok' );

            $obj = eval { from_json ( $res->content ) };

            is( @{ $obj->{data} }, 2, "Download variables by begining date.");

            ($res, $c) = ctx_request(GET '/download-variables?valid_from_end=2012-01-01');
            ok( $res->is_success, 'get is ok' );

            $obj = eval { from_json ( $res->content ) };
            is( @{ $obj->{data} }, 2, "Download variables by ending date.");

            ($res, $c) = ctx_request(GET '/download-variables?variable_id='.$var->{id});
            ok( $res->is_success, 'get is ok' );

            $obj = eval { from_json ( $res->content ) };

            is( @{ $obj->{data} }, 1, "Download variables by indicator.");


            ($res, $c) = ctx_request(GET '/download-variables?user_id=4&valid_from=2012-01-01&variable_id='.$var->{id});

            $obj = eval { from_json ( $res->content ) };

            is( @{ $obj->{data} }, 1, "Download variables by all parameters combined and a single date.");

            ($res, $c) = ctx_request(GET '/download-variables?user_id=4&valid_from_begin=2012-01-01&valid_from_end=2014-01-01&variable_id='.$var->{id}.','.$var2->{id});

            $obj = eval { from_json ( $res->content ) };

            is( @{ $obj->{data} }, 2, "Download variables by all parameters combined in a date range.");


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
