
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(Iota);

use HTTP::Request::Common;
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
                POST '/api/city',
                [
                    api_key            => 'test',
                    'city.create.name' => 'FooBar',

                ]
            );
            ok( !$res->is_success, 'invalid request' );
            is( $res->code, 400, 'invalid request' );

            ( $res, $c ) = ctx_request(
                POST '/api/city',
                [
                    api_key                 => 'test',
                    'city.create.name'      => 'Foo Bar',
                    'city.create.state_id'  => 1,
                    'city.create.latitude'  => 5666.55,
                    'city.create.longitude' => 1000.11,
                ]
            );
            ok( $res->is_success, 'city created!' );
            is( $res->code, 201, 'created!' );

            ( $res, $c ) = ctx_request(
                POST '/api/city',
                [
                    api_key                           => 'test',
                    'city.create.name'                => 'Foo Bar',
                    'city.create.state_id'            => 1,
                    'city.create.latitude'            => 5666.55,
                    'city.create.longitude'           => 1000.11,
                    'city.create.telefone_prefeitura' => '1233',
                    'city.create.summary'             => 'testexx'
                ]
            );
            ok( $res->is_success, 'city created com mesmo nome!' );
            is( $res->code, 201, 'created!' );

            use URI;
            my $uri = URI->new( $res->header('Location') );
            $uri->query_form( api_key => 'test' );

            ( $res, $c ) = ctx_request( GET $uri->path_query );
            like( $res->content, qr|foo-bar-2|, 'foo-bar-2 ok' );
            like( $res->content, qr|1233|,      'telefone ok' );
            like( $res->content, qr|testexx|,   'resumo ok' );
            like( $res->content, qr|"br"|,      'pais ok' );
            like( $res->content, qr|"SP|,       'estado ok' );

            ok( $res->is_success, 'varible exists' );
            is( $res->code, 200, 'varible exists -- 200 Success' );

            ( $res, $c ) = ctx_request( GET '/api/city?api_key=test' );
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );

            ( $res, $c ) = ctx_request( POST '/api/country/1', [ 'country.update.name' => 'BarFoo' ] );
            ok( $res->is_success, 'country updated' );
            is( $res->code, 202, 'country updated -- 202 Accepted' );

            use JSON qw(from_json);
            my $country = eval { from_json( $res->content ) };
            ok( my $updated_country = $schema->resultset('Country')->find( { id => $country->{id} } ),
                'country in DB' );
            is( $updated_country->name, 'BarFoo', 'name ok' );

            my @f = $updated_country->cities->all;
            foreach (@f) {
                is( $_->pais, 'barfoo', 'updated ok' );
                last;
            }

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
