
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(Iota);

use HTTP::Request::Common;
use Package::Stash;
use JSON;
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
            my $city = $schema->resultset('City')->create(
                {
                    uf   => 'SP',
                    name => 'Pederneiras'
                },
            );

            my $city2 = $schema->resultset('City')->create(
                {
                    uf   => 'XX',
                    name => 'AWS'
                },
            );

            my ( $res, $c ) = ctx_request(
                POST '/api/user',
                [
                    api_key                        => 'test',
                    'user.create.name'             => 'Foo Bar',
                    'user.create.email'            => 'foo@email.com',
                    'user.create.password'         => 'foobarquux1',
                    'user.create.password_confirm' => 'foobarquux1',
                    'user.create.city_id'          => $city->id,
                    'user.create.role'             => 'user',
                    'user.create.network_id'       => 2
                ]
            );
            ok( $res->is_success, 'user created' );
            is( $res->code, 201, 'user created' );
            ok( my $new_user = $schema->resultset('User')->find( { email => 'foo@email.com' } ), 'user in DB' );
            is( eval { $new_user->networks->next->name_url }, 'movim', 'criado como movimento' );
            is($new_user->networks->count, 1, 'só uma rede');


            ( $res, $c ) = ctx_request(
                POST '/api/user',
                [
                    api_key                        => 'test',
                    'user.create.name'             => 'Foo XX',
                    'user.create.email'            => 'errorme@email.com',
                    'user.create.password'         => 'foobarquux1',
                    'user.create.password_confirm' => 'foobarquux1',
                    'user.create.role'             => 'user',
                    'user.create.city_id'          => $city->id,
                    'user.create.network_id'       => 2
                ]
            );

            ok( !$res->is_success, 'user not created' );
            is( $res->code, 400, 'user not created' );
            like( $res->content, qr|user.create.network_id.invalid|, 'error na cidade ja tem movimento' );

            ( $res, $c ) = ctx_request(
                POST '/api/user',
                [
                    api_key                        => 'test',
                    'user.create.name'             => 'Foo XX',
                    'user.create.email'            => 'noterro@email.com',
                    'user.create.password'         => 'foobarquux1',
                    'user.create.password_confirm' => 'foobarquux1',
                    'user.create.city_id'          => $city->id,
                    'user.create.role'             => 'admin',
                    'user.create.network_id'       => '1',

                ]
            );

            ok( $res->is_success, 'user created na city 1 como admin da rede' );
            is( $res->code, 201, 'user created na city 1 como admin' );

            ( $res, $c ) = ctx_request(
                POST '/api/user',
                [
                    api_key                        => 'test',
                    'user.create.name'             => 'Foo XX',
                    'user.create.email'            => 'errorme@email.com',
                    'user.create.password'         => 'foobarquux1',
                    'user.create.password_confirm' => 'foobarquux1',
                    'user.create.city_id'          => $city2->id,
                    'user.create.role'             => 'user',
                    'user.create.network_id'       => 2
                ]
            );
            ok( $res->is_success, 'user created na city 2 como movimento' );
            is( $res->code, 201, 'user created na city 2 como movimento' );

            use JSON qw(encode_json);

            # update bugado pois nao pode mais existir user.update.network_id

            ( $res, $c ) = ctx_request(
                POST '/api/user/' . $new_user->id,
                [
                    api_key                  => 'test',
                    'user.update.name'       => 'Foo Bar',
                    'user.update.email'      => 'bar@email.com',
                    'user.update.network_id' => undef,
                ]
            );
            is( $res->code, 400, 'user not updated, campo negado' );

            # update normal
            ( $res, $c ) = ctx_request(
                POST '/api/user/' . $new_user->id,
                [
                    api_key                  => 'test',
                    'user.update.name'       => 'Foo Bar',
                    'user.update.email'      => 'bar@email.com',
                ]
            );
            ok( $res->is_success, 'user updated ' );
            is( $res->code, 202, 'user updated -- 202 Accepted' );

            ok( $new_user = $schema->resultset('User')->find( $new_user->id ), 'user in DB' );
            is( $new_user->institute_id, 2, 'institute_id=2 pq é movimento');

            ok( eval { $new_user->networks->next }, 'ainda tem rede (nao enviar nao pode mudar a rede)' );
            ok( my $changecity = $schema->resultset('User')->find( { email => 'errorme@email.com' } ), 'user in DB' );
            is( eval { $changecity->networks->next->name_url }, 'movim', 'criado como movimento' );
            ( $res, $c ) = ctx_request(
                POST '/api/user/' . $changecity->id,
                [
                    api_key               => 'test',
                    'user.update.name'    => 'Foo Bar',
                    'user.update.email'   => 'errorme@email.com',
                    'user.update.city_id' => $city->id,
                ]
            );

            ok( !$res->is_success, 'user updated' );
            like( $res->content, qr|"user.update.city_id.invalid|, 'user.update.city_id.invalid' );

            ( $res, $c ) = ctx_request(
                POST '/api/user/' . $changecity->id,
                [
                    api_key               => 'test',
                    'user.update.name'    => 'Foo Bar',
                    'user.update.email'   => 'errorme@email.com',
                    'user.update.city_id' => $city2->id,
                ]
            );

            ok( $res->is_success, 'user updated pra mesma city !!' );

            ( $res, $c ) = ctx_request(
                POST '/api/user/' . $changecity->id,
                [
                    api_key                  => 'test',
                    'user.update.name'       => 'Foo Bar',
                    'user.update.email'      => 'errorme@email.com',
                    'user.update.city_id'    => $city->id,
                    'user.update.network_ids' => 2,
                ]
            );

            ok( !$res->is_success, 'tbm nao pode atualizar pois cidade diferente mesmo enviando a rede igual' );
            like( $res->content, qr/"user.update.network_ids.invalid/, 'user.update.network_ids.invalid' );

            ( $res, $c ) = ctx_request(
                POST '/api/user/' . $changecity->id,
                [
                    api_key                  => 'test',
                    'user.update.name'       => 'Foo Bar XXX',
                    'user.update.email'      => 'errorme@email.com',
                    'user.update.city_id'    => $city2->id,
                    'user.update.network_ids' => 3,
                ]
            );
            ok( $res->is_success, 'mudou de rede sem mudar cidade' );

            ( $res, $c ) = ctx_request(
                POST '/api/user/' . $changecity->id,
                [
                    api_key                  => 'test',
                    'user.update.name'       => 'Foo Bar XXX',
                    'user.update.email'      => 'errorme@email.com',
                    'user.update.city_id'    => $city2->id,
                    'user.update.network_ids' => '3,2',
                ]
            );
            ok( $res->is_success, 'mudou de rede sem mudar cidade [duas redes]' );


            @Iota::TestOnly::Mock::AuthUser::_roles = qw/ superadmin /;

            ( $res, $c ) = ctx_request(
                POST '/api/institute',
                [
                    api_key                               => 'test',
                    'institute.create.name'               => 'xaXA',
                    'institute.create.short_name'         => 'xa',
                    'institute.create.can_use_custom_css' => '1',

                ]
            );

            ok( $res->is_success, 'institute created!' );
            is( $res->code, 201, 'created!' );

            my $institute = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request(
                POST '/api/network',
                [
                    api_key                       => 'test',
                    'network.create.name'         => 'prefeitura nao lembro o nome',
                    'network.create.name_url'     => 'prefeitura-2',
                    'network.create.domain_name'  => 'foo-domain.org',
                    'network.create.institute_id' => $institute->{id},

                ]
            );

            ok( $res->is_success, 'network created!' );
            is( $res->code, 201, 'created!' );

            my $network = eval { from_json( $res->content ) };

            @Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;


            ( $res, $c ) = ctx_request(
                POST '/api/user/' . $changecity->id,
                [
                    api_key                  => 'test',
                    'user.update.name'       => 'Foo Bar XXX',
                    'user.update.email'      => 'errorme@email.com',
                    'user.update.city_id'    => $city->id,
                    'user.update.network_ids' => $network->{id},
                ]
            );

            ok( $res->is_success, 'mudou de rede entao pra uma cidade livre' );


            ( $res, $c ) = ctx_request(
                POST '/api/user/' . $changecity->id,
                [
                    api_key                  => 'test',
                    'user.update.name'       => 'Foo Bar XXX',
                    'user.update.email'      => 'errorme@email.com',
                    'user.update.city_id'    => $city2->id,
                    'user.update.network_ids' => $network->{id},
                ]
            );

            ok( $res->is_success, 'mudou cidade tambem livre no instituto' );

            die 'rollback';
        }
    );
};

die $@ unless $@ =~ /rollback/;

done_testing;
