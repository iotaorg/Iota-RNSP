
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(IOTA::PCS);

use HTTP::Request::Common qw /GET POST DELETE/;
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
                    'variable.create.period'       => 'yearly',

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
                'variable.value.create.value_of_date' => '2010-02-14 17:24:32',
            ]);

            ok( $res->is_success, 'varible value created' );
            is( $res->code, 201, 'value added -- 201 ' );
            use JSON qw(from_json);
            my $value_id_123 = eval{from_json( $res->content )};

            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [   api_key                        => 'test',
                    'variable.create.name'         => 'Foo Bar2',
                    'variable.create.cognomen'     => 'foobar2',
                    'variable.create.explanation'  => 'a not foo with bar',
                    'variable.create.type'         => 'num',
                    'variable.create.period'       => 'yearly',

                ]
            );
            ok( $res->is_success, 'variable 2 created!' );
            is( $res->code, 201, 'created!' );

            # GET
            ( $res, $c ) = ctx_request( GET '/api/user/1/variable?api_key=test' );
            ok( $res->is_success, 'varibles exists' );
            is( $res->code, 200, 'varibles exists -- 200 Success' );
            use JSON qw(from_json);
            my $variable = eval{from_json( $res->content )};

            {
                ( $res, $c ) = ctx_request( GET '/api/user/1/variable?api_key=test&valid_from_begin=2012-01-01&valid_from_end=2012-01-01&variable_id=9383838' );
                ok( $res->is_success, 'varibles exists' );
                is( $res->code, 200, 'varibles exists -- 200 Success' );
                my $variable = eval{from_json( $res->content )};
                is(@{$variable->{variables}}, 0, 'sem variaveis');

            }

            is(ref $variable->{variables}, ref [], 'variables is array');
            my $count = scalar @{$variable->{variables}};
            do {
                my ( $res2, $c2 ) = ctx_request( GET '/api/user/1/variable?api_key=test&is_basic=1' );
                ok( $res2->is_success, 'varibles exists' );
                is( $res2->code, 200, 'varibles exists -- 200 Success' );

                my $variable2 = eval{from_json( $res2->content )};
                ok($count > scalar @{$variable2->{variables}}, 'less keys on is_basic is active');

            };
            my $one_is_123;


            if (ref $variable->{variables} eq ref []){
                foreach my $v (@{$variable->{variables}}){

                    ok($v->{variable_id}, 'variable_id present');
                    foreach (@{$v->{values}}){
                        $one_is_123 = $v if $_->{value} eq '123';
                    }
                }
            }
            ok($one_is_123, 'um dos valores eh 123');
            if ($one_is_123){
                is($one_is_123->{explanation}, 'a foo with bar', 'explanation is ok' );
                is($one_is_123->{type}, 'int', 'name is correct' );
                is($one_is_123->{values}[0]{id},$value_id_123->{id}, 'value_id is correct' );
            }

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
