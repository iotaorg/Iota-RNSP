
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

$ENV{HARNESS_ACTIVE_REMOVED} = 1;

sub no_point ($) {
    my ($x) = shift;
    $x =~ s/^\?\s//;
    $x;
}
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
            is( $now2, $now, 'ok, not inserted' );

            $Iota::TestOnly::Mock::AuthUser::cur_lang = 'es';
            delete $ENV{HARNESS_ACTIVE};
            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [
                    api_key                               => 'test',
                    'variable.create.name'                => 'si',
                    'variable.create.cognomen'            => 'si',
                    'variable.create.explanation'         => '1',
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
            is( $now3, $now + 6, 'inserted 6 rows 3+3' );

            my @all = $rs->search(
                {
                    user_id => $Iota::TestOnly::Mock::AuthUser::_id
                }
            )->all;

            my $out = {
                'pt-br' => [],
                'es'    => []
            };
            my $out_id = {
                'pt-br' => {},
                'es'    => {}
            };

            foreach (@all) {
                push @{ $out->{ $_->lang } }, $_->lex_value;
                $out_id->{ $_->lang }{ $_->lex_value } = $_->id;
            }
            $out->{$_} = [ sort { $a cmp $b } @{ $out->{$_} } ] for qw/pt-br es/;

            is_deeply(
                $out,
                {
                    'pt-br' => [ '? int', '? si', '? yearly', ],
                    'es'    => [ 'int',   'si',   'yearly', ]
                },
                'ok'
            );

            ( $res, $c ) = ctx_request(
                POST ':lexicon/pending',
                [
                    api_key                             => 'test',
                    'lex_' . $out_id->{'pt-br'}{'? si'} => 'sim',
                ]
            );

            like( $res->content, qr/<p>1\s/, 'traduziu 1 palavra' );

            note('loading again');
            @all = $rs->search(
                {
                    user_id => $Iota::TestOnly::Mock::AuthUser::_id
                }
            )->all;

            $out = {
                'pt-br' => [],
                'es'    => []
            };
            foreach (@all) {
                push @{ $out->{ $_->lang } }, $_->lex_value;
            }

            $out->{$_} = [ sort { no_point($a) cmp no_point($b) } @{ $out->{$_} } ] for qw/pt-br es/;
            is_deeply(
                $out,
                {
                    'pt-br' => [ '? int', 'sim', '? yearly', ],
                    'es'    => [ 'int',   'si',  'yearly', ]
                },
                'ok'
            );

            note('agora ta traduzido, entao vamos inserir um sim e ver se vira si');
            $Iota::TestOnly::Mock::AuthUser::cur_lang = 'pt-br';
            delete $ENV{HARNESS_ACTIVE};
            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [
                    api_key                               => 'test',
                    'variable.create.name'                => 'sim',
                    'variable.create.cognomen'            => 'sim',
                    'variable.create.explanation'         => '1',
                    'variable.create.type'                => 'int',
                    'variable.create.period'              => 'yearly',
                    'variable.create.source'              => '124',
                    'variable.create.measurement_unit_id' => '1',
                ]
            );
            $ENV{HARNESS_ACTIVE} = 1;
            ok( $res->is_success, 'variable created!' );
            is( $res->code, 201, 'created!' );

            $now3 = $rs->count;
            is( $now3, $now + 8, 'inserted 8 rows 4+4' );

            @all = $rs->search(
                {
                    user_id => $Iota::TestOnly::Mock::AuthUser::_id
                }
            )->all;

            $out = {
                'pt-br' => [],
                'es'    => []
            };
            my $translated_from_lexicon;

            foreach (@all) {
                push @{ $out->{ $_->lang } }, $_->lex_value;

                print STDERR sprintf "# %s => %s, key '%s' => '%s'\n", $_->origin_lang, $_->lang, $_->lex_key,
                  $_->lex_value;

                $translated_from_lexicon->{ $_->lex_key } = $_->lex_value if $_->translated_from_lexicon;

            }
            $out->{$_} = [ sort { no_point $a cmp no_point $b } @{ $out->{$_} } ] for qw/pt-br es/;

            is( $translated_from_lexicon->{sim}, 'si', 'ok, traduziu sozinho!' );

            is_deeply(
                $out,
                {
                    'pt-br' => [ '? int', 'sim', 'sim', '? yearly', ],
                    'es'    => [ 'int',   'si',  'si',  'yearly', ]
                },
                'ok'
            );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
