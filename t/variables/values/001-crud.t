
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Catalyst::Test q(RNSP::PCS);

use HTTP::Request::Common qw /GET POST DELETE/;
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
                    'variable.create.type'         => 'int',
                ]
            );
            ok( $res->is_success, 'variable created!' );
            is( $res->code, 201, 'created!' );

            use URI;
            my $uri = URI->new( $res->header('Location') . '/value' );
            $uri->query_form( api_key => 'test' );

            # POST
            ( $res, $c ) = ctx_request( POST $uri->path_query , [
                'variable.value.create.value'         => '123',
                'variable.value.create.value_of_date' => 'today',
            ]);

            ok( $res->is_success, 'varible value created' );
            is( $res->code, 201, 'value added -- 201 ' );

            # GET
            $uri = URI->new( $res->header('Location') );
            $uri->query_form( api_key => 'test' );
            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'varible exists' );
            is( $res->code, 200, 'varible exists -- 200 Success' );

            # UPDATE
            ( $res, $c ) = ctx_request( POST $uri->path_query, [
                'variable.value.update.value'         => '456',
                'variable.value.update.value_of_date' => '2012-12-22 14:22:44',
            ] );
            ok( $res->is_success, 'varible updated' );
            is( $res->code, 202, 'varible exists -- 202 accepted' );

            use JSON qw(decode_json);
            my $variable = eval{decode_json( $res->content )};

            ok(
                my $updated_var =
                $schema->resultset('VariableValue')->find( { id => $variable->{id} } ),
                'var in DB'
            );

            is($updated_var->value, '456', 'value is relly updated');
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
