
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(Iota);

use JSON;
use HTTP::Request::Common qw(GET POST DELETE PUT);

use Package::Stash;

use Iota::TestOnly::Mock::AuthUser;

my $schema = Iota->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::TestOnly::Mock::AuthUser->new;

$Iota::TestOnly::Mock::AuthUser::_id    = 1;
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ superadmin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

eval {
    $schema->txn_do(
        sub {
            my ( $res, $c ) = ctx_request( GET '/api/institute/2/stats?api_key=test' );
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );

            my $list = eval { from_json( $res->content ) };
            my $epec = {
                'stats' => [
                        {
                            'total_regions3' => undef,
                            'name' => 'movimento2',
                            'total_values2' => undef,
                            'total_vars_last_perc' => undef,
                            'total_values3' => undef,
                            'total_vars_last' => undef,
                            'total_regions3_perc' => undef,
                            'total_regions2' => undef,
                            'total_vars' => '15',
                            'user_id' => 6,
                            'city_name' => 'Outracidade',
                            'total_regions2_perc' => undef
                        },
                        {
                            'total_regions3' => undef,
                            'name' => 'movimento',
                            'total_values2' => undef,
                            'total_vars_last_perc' => undef,
                            'total_values3' => undef,
                            'total_vars_last' => undef,
                            'total_regions3_perc' => undef,
                            'total_regions2' => undef,
                            'total_vars' => '15',
                            'user_id' => 5,
                            'city_name' => "S\x{c3}\x{a3}o Paulo",
                            'total_regions2_perc' => undef
                        },
                        {
                            'total_regions3' => undef,
                            'name' => 'latina',
                            'total_values2' => undef,
                            'total_vars_last_perc' => undef,
                            'total_values3' => undef,
                            'total_vars_last' => undef,
                            'total_regions3_perc' => undef,
                            'total_regions2' => undef,
                            'total_vars' => '15',
                            'user_id' => 7,
                            'city_name' => "S\x{c3}\x{a3}o Paulo",
                            'total_regions2_perc' => undef
                        }
                        ]
            };
            is_deeply($list, $epec, 'ok');


            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
