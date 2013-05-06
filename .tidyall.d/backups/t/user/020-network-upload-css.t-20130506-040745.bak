
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(Iota);

use HTTP::Request::Common;
use Package::Stash;
use Path::Class qw(dir);
use Iota::TestOnly::Mock::AuthUser;

my $schema = Iota->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::TestOnly::Mock::AuthUser->new;

$Iota::TestOnly::Mock::AuthUser::_id    = 2;
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );
use JSON;
eval {
    $schema->txn_do(
        sub {
            my $id = 2;
            my $url_user = '/api/user/' . $id;
            my ( $res, $c ) = ctx_request(
                POST $url_user . '/arquivo/custom.css',
                'Content-Type' => 'form-data',
                Content =>
                [   api_key                        => 'test',
                    'arquivo' => ["$Bin/network_test.css"],
                ]
            );

            ( $res, $c ) = ctx_request( GET $url_user );
            {
                my $obj = from_json( $res->content );

                like( $obj->{files}{'custom.css'}, qr|css|, 'version updated' );
            }
            my $filename = "user_${id}_custom.css_network_test.css";
            my $name = Iota->config->{private_path} =~ /^\//o ?
                dir(Iota->config->{private_path})->resolve . '/' . $filename :
                Iota->path_to( $c->config->{private_path} , $filename );

            ok(-e $name, $name . ' image exists');

            unlink($name) if -e $name;


            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
