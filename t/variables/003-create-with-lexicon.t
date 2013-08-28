
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(Iota);

use HTTP::Request::Common;
use Package::Stash;

use Iota::TestOnly::Mock::AuthUser;

my $schema = Iota->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::TestOnly::Mock::AuthUser->new;

$Iota::TestOnly::Mock::AuthUser::_id    = 2;
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

eval {
    $schema->txn_do(
        sub {
            my ( $res, $c );

            my $rs = $schema->resultset('Lexicon');

            my $now = $rs->count;
            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [
                    api_key                               => 'test',
                    'variable.create.name'                => 'testando',
                    'variable.create.cognomen'            => 'isso_daqui',
                    'variable.create.explanation'         => 'todos',
                    'variable.create.type'                => 'int',
                    'variable.create.period'              => 'yearly',
                    'variable.create.source'              => '124',
                    'variable.create.measurement_unit_id' => '1',
                ]
            );
            ok( $res->is_success, 'variable created!' );
            is( $res->code, 201, 'created!' );

            my $now2 = $rs->count;
            is ($now2, $now, 'ok, not inserted');

            delete $ENV{HARNESS_ACTIVE};
            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [
                    api_key                               => 'test',
                    'variable.create.name'                => 'testando',
                    'variable.create.cognomen'            => 'isso_daqui2',
                    'variable.create.explanation'         => 'todos',
                    'variable.create.type'                => 'int',
                    'variable.create.period'              => 'yearly',
                    'variable.create.source'              => '124',
                    'variable.create.measurement_unit_id' => '1',
                ]
            );
            $ENV{HARNESS_ACTIVE} = 1;
            ok( $res->is_success, 'variable created!' );
            is( $res->code, 201, 'created!' );

            my $now3 = $rs->count;
            is ($now3, $now+10, 'inserted 10 rows 5+5');

            my @all = $rs->search({
                user_id => $Iota::TestOnly::Mock::AuthUser::_id
            })->all;

            my $out = {
                'pt-br' => [],
                'es' => []
            };
            foreach (@all) {
                push @{$out->{$_->lang}}, $_->lex_value;
            }
            $out->{$_} = [sort {$a cmp $b} @{$out->{$_}}] for qw/pt-br es/;

            is_deeply($out, {
                'pt-br' => ['int', 'isso_daqui2', 'testando', 'todos', 'yearly'],
                'es' => ['? int', '? isso_daqui2', '? testando', '? todos', '? yearly']
            }, 'ok');
            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
