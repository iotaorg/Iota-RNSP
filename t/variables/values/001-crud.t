
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Catalyst::Test q(Iota);

use HTTP::Request::Common qw /GET POST DELETE/;
use Package::Stash;

use Iota::TestOnly::Mock::AuthUser;

my $schema = Iota->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::TestOnly::Mock::AuthUser->new;

$Iota::TestOnly::Mock::AuthUser::_id    = 1;
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

eval {
    $schema->txn_do(
        sub {
            my ( $res, $c );
            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [   api_key                        => 'test',
                    'variable.create.name'         => 'FooBar',
                ]
            );
            ok( !$res->is_success, 'invalid request' );
            is( $res->code, 400, 'invalid request' );


            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [   api_key                        => 'test',
                    'variable.create.name'         => 'Foo Bar',
                    'variable.create.cognomen'     => 'foobar',
                    'variable.create.period'       => 'yearly',
                    'variable.create.explanation'  => 'a foo with bar',
                    'variable.create.type'         => 'num',
                ]
            );
            ok( $res->is_success, 'variable created!' );
            is( $res->code, 201, 'created!' );


            use URI;
            my $uri = URI->new( $res->header('Location') . '/value' );
            $uri->query_form( api_key => 'test' );

            my $variable_url = $uri->path_query;
            # POST
            ( $res, $c ) = ctx_request( POST $variable_url, [
                'variable.value.create.value'         => '123AAA',
                'variable.value.create.value_of_date' => '2012-12-22 14:22:44',
            ]);

            ok( !$res->is_success, 'variable value not created' );
            is( $res->code, 400, 'value added -- 400 ' );
            like($res->content, qr/value.invalid/, 'valor invalido');

            # sem valor
            ( $res, $c ) = ctx_request( POST $variable_url, [
                'variable.value.create.value'         => '',
                'variable.value.create.source'        => 'AAAA',
                'variable.value.create.value_of_date' => '2022-12-22 14:22:44',
            ]);
            #ok( !$res->is_success, 'variable value not created' );
            #is( $res->code, 400, 'value added -- 400 ' );
            # TODO cadastrar antes a justificativa
            ok( $res->is_success, 'variable value created' );
            is( $res->code, 201, 'value added -- 2001' );

            # sem valor 2
            ( $res, $c ) = ctx_request( POST $variable_url, [
                'variable.value.create.value_of_date' => '2022-12-22 14:22:44',
            ]);
            ok( !$res->is_success, 'variable value not created' );
            is( $res->code, 400, 'value added -- 400 ' );

            ## sem valor, MAS COM justificativa
            #( $res, $c ) = ctx_request( POST $variable_url, [
            #    'variable.value.create.justification_of_missing_field' => 'lala',
            #    'variable.value.create.value_of_date' => '2022-12-22 14:22:44',
            #]);
            #ok( $res->is_success, 'variable justification_of_missing_field created' );
            #is( $res->code, 201, 'value added -- 201 ' );

            ( $res, $c ) = ctx_request( POST $variable_url, [
                'variable.value.create.value'         => '123.24',
                'variable.value.create.source'        => 'AAAA',
                'variable.value.create.value_of_date' => '2012-12-22 14:22:44',
            ]);

            ok( $res->is_success, 'variable value created' );
            is( $res->code, 201, 'value added -- 201 ' );

            # GET
            $uri = URI->new( $res->header('Location') );
            $uri->query_form( api_key => 'test' );
            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'variable exists' );
            is( $res->code, 200, 'variable exists -- 200 Success' );

            # tem q dar erro porque ja tem outra criada nesta mesma data [e esse nao eh o metodo de PUT]

            ( $res, $c ) = ctx_request( POST $variable_url, [
                'variable.value.create.value'         => '123',
                'variable.value.create.source'        => 'AAAA',
                'variable.value.create.value_of_date' => '2012-12-20 14:22:44',
            ]);

            ok( !$res->is_success, 'variable value not created' );
            is( $res->code, 400, 'expected error' );

            # UPDATE
            ( $res, $c ) = ctx_request( POST $uri->path_query, [
                'variable.value.update.value'         => '456',
                'variable.value.update.source'        => 'AAAA',
                'variable.value.update.observations'  => 'observations',
                'variable.value.update.value_of_date' => '2012-12-22 14:22:44',
            ] );
            ok( $res->is_success, 'variable updated' );
            is( $res->code, 202, 'variable exists -- 202 accepted' );


            my ( $res2, $c2 ) = ctx_request( POST $uri->path_query, [
                'variable.value.update.value'         => '456',
                'variable.value.update.value_of_date' => '2011-12-22 14:22:44',
            ] );
            ok( !$res2->is_success, 'variable not updated [changed perid]' );
            is( $res2->code, 400, 'expected error' );

            use JSON qw(from_json);
            my $variable = eval{from_json( $res->content )};

            ok(
                my $updated_var =
                $schema->resultset('VariableValue')->find( { id => $variable->{id} } ),
                'var in DB'
            );

            is($updated_var->value, '456', 'value is relly updated');
            is($updated_var->source, 'AAAA', 'source relly updated');
            is($updated_var->observations, 'observations', 'observations updated');
            is($updated_var->value_of_date->datetime, '2012-12-22T14:22:44', 'value date as well updated');

            # DELETE
            ( $res, $c ) = ctx_request( DELETE $uri->path_query );
            ok( $res->is_success, 'var deleted' );
            is( $res->code, 204, 'var deleted - 204 no content' );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
