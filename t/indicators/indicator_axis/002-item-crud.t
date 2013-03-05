use strict;
use warnings;
use JSON qw(from_json);

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Catalyst::Test q(Iota);


use HTTP::Request::Common qw(GET POST DELETE PUT);

use Package::Stash;

use Iota::TestOnly::Mock::AuthUser;

my $schema = Iota->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::TestOnly::Mock::AuthUser->new;

$Iota::TestOnly::Mock::AuthUser::_id    = 1;
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ user /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

eval {
    $schema->txn_do(
        sub {
            my ( $res, $c );
            ( $res, $c ) = ctx_request(
                POST '/api/user_indicator_axis',
                [   api_key                    => 'test',
                    'user_indicator_axis.create.name'       => 'FooBar',
                ]
            );

            ok( $res->is_success, 'user_indicator_axis created!' );
            is( $res->code, 201, 'created!' );

            my $user_indicator_axis = eval{from_json( $res->content )};


            use URI;
            my $uri = URI->new( $res->header('Location') );
            $uri->query_form( api_key => 'test' );

            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'user_indicator_axis exists' );
            is( $res->code, 200, 'user_indicator_axis exists -- 200 Success' );

            like($res->content, qr|FooBar|, 'FooBar ok');

            @Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;
            ( $res, $c ) = ctx_request(
                POST '/api/indicator',
                [   api_key                         => 'test',
                    'indicator.create.name'         => 'XX',
                    'indicator.create.formula'      => '1',
                    'indicator.create.goal'         => '33',
                    'indicator.create.axis_id'      => '2',
                    'indicator.create.explanation'  => 'explanation',
                    'indicator.create.source'       => 'me',
                    'indicator.create.goal_source'  => '@fulano',
                    'indicator.create.chart_name'   => 'pie',
                    'indicator.create.goal_operator'=> '<=',
                    'indicator.create.tags'         => 'you,me,she',
                    'indicator.create.indicator_roles' => '_prefeitura,_movimento'

                ]
            );
            ok( $res->is_success, 'indicator created!' );
            my $indicator = eval{from_json( $res->content )};

            @Iota::TestOnly::Mock::AuthUser::_roles = qw/ user /;
            my $obj_uri = '/api/user_indicator_axis/' . $user_indicator_axis->{id}. '/item';

            ( $res, $c ) = ctx_request(
                POST $obj_uri ,
                [
                    'user_indicator_axis_item.create.indicator_id' => $indicator->{id},
                ]
            );
            ok( $res->is_success, 'user_indicator_axis created!' );
            is( $res->code, 201, 'created!' );

            $uri = URI->new( $res->header('Location') );
            $uri->query_form( api_key => 'test' );

            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'user_indicator_axis_item exists' );
            is( $res->code, 200, 'user_indicator_axis_item exists -- 200 Success' );

            my $user_indicator_axis_item = eval{from_json( $res->content )};
            is($user_indicator_axis_item->{position}, 0, 'zero position');


            ( $res, $c ) = ctx_request( GET '/api/user_indicator_axis/' . $user_indicator_axis->{id} );
            ok( $res->is_success, 'user_indicator_axis_item exists' );
            is( $res->code, 200, 'user_indicator_axis_item exists -- 200 Success' );

            my $obj = eval{from_json( $res->content )};
            is_deeply($obj->{items}[0], $user_indicator_axis_item, 'same item!');


            $obj_uri = '/api/user_indicator_axis/' .
                $user_indicator_axis->{id}. '/item/' . $user_indicator_axis_item->{id};
            ( $res, $c ) = ctx_request(
                POST $obj_uri ,
                [
                    'user_indicator_axis_item.update.position' => 2
                ]
            );
            ok( $res->is_success, 'user_indicator_axis_item updated!' );
            is( $res->code, 202, 'updated!' );


            ( $res, $c ) = ctx_request( GET '/api/user_indicator_axis/' . $user_indicator_axis->{id} );
            ok( $res->is_success, 'user_indicator_axis_item exists' );
            is( $res->code, 200, 'user_indicator_axis_item exists -- 200 Success' );

            $obj = eval{from_json( $res->content )};
            is($obj->{items}[0]{position}, 2, 'item updated!');



            ( $res, $c ) = ctx_request(
                DELETE $obj_uri ,
                [
                    'user_indicator_axis_item.update.position' => 2
                ]
            );
            ok( $res->is_success, 'user_indicator_axis_item updated!' );
            is( $res->code, 204, 'deleted!' );


            ( $res, $c ) = ctx_request( GET '/api/user_indicator_axis/' . $user_indicator_axis->{id} );
            ok( $res->is_success, 'user_indicator_axis_item exists' );
            is( $res->code, 200, 'user_indicator_axis_item exists -- 200 Success' );

            $obj = eval{from_json( $res->content )};
            is($obj->{items}[0], undef, 'item deleted!');


            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
