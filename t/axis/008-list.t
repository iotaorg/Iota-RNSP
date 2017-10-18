
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More use Catalyst::Test q(Iota);

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

            # GET
            ( $res, $c ) = ctx_request( GET '/api/axis?api_key=test' );
            ok( $res->is_success, 'axis list ok' );
            is( $res->code, 200, '200 Success' );

            use JSON qw(from_json);
            my $axis = eval { from_json( $res->content ) };

            is( ref $axis->{axis}, ref [], 'axis is array' );
            ok( $axis->{axis}[0]{name}, 'defined name' );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
