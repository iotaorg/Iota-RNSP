
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use File::Temp qw/ tempfile /;
use Text::CSV_XS;
use Catalyst::Test q(Iota);

use HTTP::Request::Common;
use Package::Stash;
use Path::Class qw(dir);
use Iota::TestOnly::Mock::AuthUser;
use JSON;

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
            my ( $res, $c ) = ctx_request(
                POST '/api/user',
                [
                    api_key                                 => 'test',
                    'user.create.name'                      => 'Foo Bar',
                    'user.create.email'                     => 'foo@email.com',
                    'user.create.password'                  => 'foobarquux1',
                    'user.create.nome_responsavel_cadastro' => 'nome_responsavel_cadastro',
                    'user.create.password_confirm'          => 'foobarquux1',
                    'user.create.city_id'                   => $city->id,
                    'user.create.role'                      => 'admin',
                    'user.create.network_id'                => '1',
                    'user.create.city_summary'              => 'testeteste'
                ]
            );
            ok( $res->is_success, 'user created' );
            is( $res->code, 201, 'user created' );

            my $user1_uri = $res->header('Location');
            my $user1 = eval { from_json( $res->content ) };
=pod
            for my $invalido_nome(qw/invalido.kml invalido2.kml invalido3.kml/){
                ( $res, $c ) = ctx_request(
                    POST $user1_uri. '/kml',
                    'Content-Type' => 'form-data',
                    Content        => [
                        api_key   => 'test',
                        'arquivo' => [$Bin.'/'.$invalido_nome],
                    ]
                );
                ok( $res->is_success, 'OK' );
                is( $res->code, 200, 'upload done!' );

                is( $res->content, '{"error":"Unssuported KML\n"}', 'nao suportado formato/invalido');
            }
=cut
            ( $res, $c ) = ctx_request(
                POST $user1_uri. '/kml',
                'Content-Type' => 'form-data',
                Content        => [
                    api_key   => 'test',
                    'arquivo' => [$Bin.'/municipio_ac.kml'],
                ]
            );
            ok( $res->is_success, 'OK' );
            is( $res->code, 200, 'upload done!' );
            my $ret1 = eval { from_json( $res->content ) };
            is( @{$ret1->{vec}}, 22, 'tem 22 vetores');
            undef $ret1;

            ( $res, $c ) = ctx_request(
                POST $user1_uri. '/kml',
                'Content-Type' => 'form-data',
                Content        => [
                    api_key   => 'test',
                    'arquivo' => [$Bin.'/municipio_teste.kml'],
                ]
            );
            ok( $res->is_success, 'OK' );
            is( $res->code, 200, 'upload done!' );
            my $ret2 = eval { from_json( $res->content ) };
            is( @{$ret2->{vec}}, 2, 'tem 2 vetores');

            is_deeply($ret2, {
                'vec' => [
                            {
                            'latlng' => [
                                            [
                                            '-69.6214070',
                                            '-8.2150924'
                                            ],
                                            [
                                            '-69.5869513',
                                            '-8.2445153'
                                            ]
                                        ],
                            'name' => undef
                            },
                            {
                            'latlng' => [
                                            [
                                            '-68.2793555',
                                            '-9.8218697'
                                            ]
                                        ],
                            'name' => undef
                            }
                        ]
                }, 'parse ok!');

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
