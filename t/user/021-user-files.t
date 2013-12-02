
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
                POST $url_user . '/file',
                'Content-Type' => 'form-data',
                Content        => [
                    api_key                        => 'test',
                    'user.file.create.class_name'  => 'a',
                    'user.file.create.description' => 'b',
                    'user.file.create.public_name' => 'z',

                    'arquivo' => ["$Bin/img_teste.gif"],
                ]
            );
            ok( $res->is_success, 'OK' );
            is( $res->code, 200, 'file created!' );

            my $obj = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request( GET $url_user . '/file/' . $obj->{id} );
            $obj = eval { from_json( $res->content ) };
            is( $obj->{description}, 'b' );
            is( $obj->{class_name},  'a' );
            is( $obj->{public_name}, 'z' );

            ok( -e $obj->{private_path} );

            ( $res, $c ) = ctx_request( GET $url_user . '/file/' );
            ok( $res->is_success, 'list' );
            my $lst = eval { from_json( $res->content ) };

            is_deeply( $lst->{files}[0], $obj );

            ( $res, $c ) = ctx_request( DELETE $url_user . '/file/' . $obj->{id} );
            ok( $res->is_success, 'delete' );

            ok( !-e $obj->{private_path} );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
