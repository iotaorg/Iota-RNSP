

use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(RNSP::PCS);

use HTTP::Request::Common;
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

        my ( $res, $c );
        ( $res, $c ) = ctx_request(
            POST '/api/indicator',
            [   api_key                         => 'test',
                'indicator.create.name'         => 'Foo Bar',
                'indicator.create.goal'         => '11',
                'indicator.create.formula'      => '5 / 2',
                'indicator.create.axis_id'       => '1',
                'indicator.create.indicator_roles' => '_prefeitura,_movimento',
            ]
        );
        ok( $res->is_success, 'indicator created!' );
        is( $res->code, 201, 'created!' );

        use URI;
        my $uri = URI->new( $res->header('Location') );
        $uri->query_form( api_key => 'test' );


        # update indicator
        ( $res, $c ) = ctx_request(
            POST $uri->path_query,
            [
                'indicator.update.goal'         => '22',
            ]
        );
        ok( $res->is_success, 'indicator updated' );
        is( $res->code, 202, 'indicator updated -- 202 Accepted' );

        use JSON qw(from_json);
        my $indicator = eval{from_json( $res->content )};

        ok(
            my $updated_indicator =
            $schema->resultset('Indicator')->find( { id => $indicator->{id} } ),
            'indicator in DB'
        );

        is( $updated_indicator->name, 'Foo Bar', 'name not change!' );
        is( $updated_indicator->goal, '22', 'goal updated ok' );


      die 'rollback';
    }
  );

};

die $@ unless $@ =~ /rollback/;

done_testing;
