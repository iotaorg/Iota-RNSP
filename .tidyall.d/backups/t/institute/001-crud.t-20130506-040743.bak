
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(Iota);


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
            my ( $res, $c );
            ( $res, $c ) = ctx_request(
                POST '/api/institute',
                [   api_key                    => 'test',
                    'institute.create.name'       => 'aPrefeitura',
                    'institute.create.short_name'   => 'pref',
                    'institute.create.can_use_custom_css'   => '1',
                    'institute.create.institute_id'   => '1',

                ]
            );

            ok( $res->is_success, 'institute created!' );
            is( $res->code, 201, 'created!' );

            use URI;
            my $uri = URI->new( $res->header('Location') );
            $uri->query_form( api_key => 'test' );

            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'institute exists' );
            is( $res->code, 200, 'institute exists -- 200 Success' );

            like($res->content, qr|"aPrefeitura"|, 'name ok');
            like($res->content, qr|"pref"|, 'short_name ok');


            my $obj_uri = $uri->path_query;
            ( $res, $c ) = ctx_request(
                POST $obj_uri,
                [
                    'institute.update.name'         => 'BarFoo',

                ]
            );
            ok( $res->is_success, 'institute updated' );
            is( $res->code, 202, 'institute updated -- 202 Accepted' );

            use JSON qw(from_json);
            my $institute = eval{from_json( $res->content )};
            ok(
                my $updated_institute =
                $schema->resultset('Institute')->find( { id => $institute->{id} } ),
                'institute in DB'
            );
            is( $updated_institute->name, 'BarFoo', 'name ok' );
            ok( $updated_institute->can_use_custom_css, 'can_use_custom_css' );


            ( $res, $c ) = ctx_request( GET '/api/institute?api_key=test');
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );

            my $list = eval{from_json( $res->content )};
            is($list->{institute}[2]{name}, 'BarFoo', 'name from list ok');
            is($list->{institute}[2]{users_can_edit_groups}, '0', 'users_can_edit_groups 0');
            is($list->{institute}[2]{can_use_custom_css}, '1', 'can_use_custom_css 1');
            is($list->{institute}[2]{users_can_edit_value}, '0', 'users_can_edit_value 0');
            is($list->{institute}[2]{can_use_custom_pages}, '0', 'can_use_custom_pages 0');


            ( $res, $c ) = ctx_request(
                DELETE $obj_uri
            );
            ok( $res->is_success, 'institute deleted' );
            is( $res->code, 204, 'institute deleted -- 204' );

            ( $res, $c ) = ctx_request( GET '/api/institute?api_key=test');
            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );


            $list = eval{from_json( $res->content )};
            is(@{$list->{institute}}, '2', 'default list');

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
