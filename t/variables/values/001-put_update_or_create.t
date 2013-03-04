
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Catalyst::Test q(IOTA::PCS);

use HTTP::Request::Common qw /GET POST/;
use Package::Stash;

use IOTA::PCS::TestOnly::Mock::AuthUser;

my $schema = IOTA::PCS->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = IOTA::PCS::TestOnly::Mock::AuthUser->new;

$IOTA::PCS::TestOnly::Mock::AuthUser::_id    = 1;
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
                    'variable.create.name'         => 'Foo Bar',
                    'variable.create.cognomen'     => 'foobar',
                    'variable.create.period'       => 'weekly',
                    'variable.create.explanation'  => 'a foo with bar',
                    'variable.create.type'         => 'int',
                ]
            );
            ok( $res->is_success, 'variable created!' );
            is( $res->code, 201, 'created!' );


            use URI;
            my $uri = URI->new( $res->header('Location') . '/value' );
            $uri->query_form( api_key => 'test' );

            my $variable_url = $uri->path_query;

            # TODO PUT sem valor e sem justificativa
            # my $req = POST $variable_url, [
            #    'variable.value.put.value_of_date' => '2012-10-10 14:22:44',
            #];
            #$req->method('PUT');
            #( $res, $c ) = ctx_request($req);

            #ok( !$res->is_success, 'variable not updated' );
            #is( $res->code, 400, 'value added -- 400' );

            # PUT sem valor
            #my $req = POST $variable_url, [
            #    'variable.value.put.justification_of_missing_field' => 'hehe',
            #    'variable.value.put.value_of_date' => '2012-10-10 14:22:44',
            #];
            #$req->method('PUT');
            #( $res, $c ) = ctx_request($req);

            #ok( $res->is_success, 'variable value created' );
            #is( $res->code, 201, 'value added -- 201 ' );

            # PUT normal
            my $req = POST $variable_url, [
                'variable.value.put.value'         => '123',
                'variable.value.put.value_of_date' => '2012-10-10 14:22:44',
            ];
            $req->method('PUT');
            ( $res, $c ) = ctx_request($req);

            ok( $res->is_success, 'variable value created' );
            is( $res->code, 201, 'value added -- 201 ' );


            # GET
            my $week1_url = $res->header('Location');
            $uri = URI->new( $week1_url );
            $uri->query_form( api_key => 'test' );
            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'variable exists' );
            is( $res->code, 200, 'variable exists -- 200 Success' );
            use JSON qw(from_json);
            my $variable = eval{from_json( $res->content )};

            is ($variable->{value}, '123', 'variable created with correct value');
            is ($variable->{value_of_date}, '2012-10-10 14:22:44', 'variable created with correct value date');

            $req = POST $variable_url, [
                'variable.value.put.value'         => '4456',
                'variable.value.put.value_of_date' => '2012-10-11 14:22:44', # dia 11 continua na mesma semana
            ];
            $req->method('PUT');
            ( $res, $c ) = ctx_request($req);

            # GET
            is($week1_url, $res->header('Location'), 'same variable updated!');
            $uri = URI->new( $week1_url );
            $uri->query_form( api_key => 'test' );
            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'variable exists' );
            is( $res->code, 200, 'variable exists -- 200 Success' );

            $variable = eval{from_json( $res->content )};

            is ($variable->{value}, '4456', 'variable updated with correct value');
            is ($variable->{value_of_date}, '2012-10-11 14:22:44', 'variable updated with correct value date');

            $req = POST $variable_url, [
                'variable.value.put.value'         => '4456',
                'variable.value.put.value_of_date' => '2012-10-17 14:22:44', # mas dia 17 eh a proxima
            ];
            $req->method('PUT');
            ( $res, $c ) = ctx_request($req);
            ok($week1_url ne $res->header('Location'), 'variable change!!');

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
