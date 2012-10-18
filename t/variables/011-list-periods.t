
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

            my $ret = $schema->schema->get_weeks_of_year(2012);
            is($ret->[51]{period_begin}, '2012-12-23', 'ultima semana de 2012 ok');

            is($ret->[0]{period_begin}, '2012-01-01', 'primeira semana de 2012 ok');

            $ret = $schema->schema->get_weeks_of_year(2011);
            is($ret->[0]{period_begin}, '2011-01-02', 'primeira semana de 2011 ok');

            my ( $res, $c ) = ctx_request( GET '/api/period/year/2012/week' );
            ok( $res->is_success, 'weeks success' );
            is( $res->code, 200, '200 Success' );

            use JSON qw(decode_json);
            my $week = eval{decode_json( $res->content )};
            ok($week->{options}[0]{text}, 'text is present');
            ok($week->{options}[0]{value}, 'value is present');


            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
