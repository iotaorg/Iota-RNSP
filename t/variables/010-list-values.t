
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

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
                'variable.value.create.value'    => '123',
            ]);

            ok( $res->is_success, 'varible value created' );
            is( $res->code, 201, 'value added -- 201 ' );
            use JSON qw(decode_json);
            my $value_id_123 = eval{decode_json( $res->content )};

            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [   api_key                        => 'test',
                    'variable.create.name'         => 'Foo Bar2',
                    'variable.create.cognomen'     => 'foobar2',
                    'variable.create.explanation'  => 'a not foo with bar',
                    'variable.create.type'         => 'num',
                ]
            );
            ok( $res->is_success, 'variable 2 created!' );
            is( $res->code, 201, 'created!' );

            # GET
            ( $res, $c ) = ctx_request( GET '/api/user/1/variable?api_key=test' );

            ok( $res->is_success, 'varible exists' );
            is( $res->code, 200, 'varible exists -- 200 Success' );

            use JSON qw(decode_json);
            my $variable = eval{decode_json( $res->content )};

            is(ref $variable->{variables}, ref [], 'variables is array');
            my $one_is_123;

            if (ref $variable->{variables} eq ref []){
                foreach (@{$variable->{variables}}){

                    ok($_->{variable_id}, 'variable_id present');
                    $one_is_123 = $_ if $_->{value} && $_->{value} eq '123';

                }
            }
            ok($one_is_123, 'um dos valores eh 123');
            if ($one_is_123){
                is($one_is_123->{explanation}, 'a foo with bar', 'explanation is ok' );
                is($one_is_123->{type}, 'int', 'name is correct' );
                is($one_is_123->{value_id},$value_id_123->{id}, 'value_id is correct' );
            }

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
