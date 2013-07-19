
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use JSON qw(from_json);
use Catalyst::Test q(Iota);

use HTTP::Request::Common qw(GET POST DELETE PUT);
use Package::Stash;
use Path::Class qw(dir);
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
            my ( $res, $c ) = ctx_request(
                POST '/api/user',
                [
                    api_key                                 => 'test',
                    'user.create.name'                      => 'Foo Bar',
                    'user.create.email'                     => 'foo@email.com',
                    'user.create.password'                  => 'foobarquux1',
                    'user.create.nome_responsavel_cadastro' => 'nome_responsavel_cadastro',
                    'user.create.password_confirm'          => 'foobarquux1',
                    'user.create.role'                      => 'admin',
                    'user.create.network_id'                => '1',

                    'user.create.city_summary' => 'testeteste'
                ]
            );

            ok( $res->is_success, 'user created' );
            is( $res->code, 201, 'user created' );

            ok( my $new_user = $schema->resultset('User')->find( { email => 'foo@email.com' } ), 'user in DB' );

            my $url_user = $res->header('Location');

            ( $res, $c ) = ctx_request(
                POST $url_user . '/region',
                'Content-Type' => 'form-data',
                Content        => [
                    api_key                                         => 'test',
                    'user.region.create.depth_level'                => '2',
                    'user.region.create.region_classification_name' => 'lala',
                ]
            );
            ok( $res->is_success, 'OK' );
            is( $res->code, 201, 'region created!' );

            my $obj = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request( GET $url_user . '/region/' . $obj->{id} );
            $obj = eval { from_json( $res->content ) };
            is( $obj->{region_classification_name}, 'lala' );

            ( $res, $c ) = ctx_request( GET $url_user . '/region/' );
            ok( $res->is_success, 'list' );
            my $lst = eval { from_json( $res->content ) };

            is_deeply( $lst->{regions}[0], $obj );

            ( $res, $c ) = ctx_request( DELETE $url_user . '/region/' . $obj->{id} );
            ok( $res->is_success, 'delete' );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
