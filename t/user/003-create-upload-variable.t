
use strict;
use warnings;

use Test::More;
use utf8;
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

$Iota::TestOnly::Mock::AuthUser::_id    = 1;
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

eval {
    $schema->txn_do(
        sub {
            my $city = $schema->resultset('City')->create(
                {
                    uf   => 'SP',
                    name => 'Pederneiras'
                },
            );

            my ( $res, $c );
            ( $res, $c ) = ctx_request(
                POST '/api/user',
                [
                    api_key                                 => 'test',
                    'user.create.name'                      => 'Foo Bar',
                    'user.create.email'                     => 'foo@email.com',
                    'user.create.password'                  => 'foobarquux1',
                    'user.create.nome_responsavel_cadastro' => 'nome_responsavel_cadastro',
                    'user.create.password_confirm'          => 'foobarquux1',
                    'user.create.city_id'                   => $city->id,
                    'user.create.role'                      => 'admin',
                    'user.create.network_id'                => '1',
                    'user.create.city_summary'              => 'testeteste'
                ]
            );
            ok( $res->is_success, 'user created' );
            is( $res->code, 201, 'user created' );

            ( $res, $c ) = ctx_request(
                POST '/api/variable/value_via_file',
                'Content-Type' => 'form-data',
                Content        => [
                    api_key   => 'test',
                    'arquivo' => ["$Bin/teste-upload.xlsx"],
                ]
            );
            ok( $res->is_success, 'OK' );
            is( $res->code, 200, 'upload done!' );

            like( $res->content, qr/Linhas aceitas: 3\\n"/, '3 linhas no XLSX' );

            ( $res, $c ) = ctx_request(
                POST '/api/variable/value_via_file',
                'Content-Type' => 'form-data',
                Content        => [
                    api_key   => 'test',
                    'arquivo' => ["$Bin/teste-upload.xls"],
                ]
            );
            ok( $res->is_success, 'OK' );
            is( $res->code, 200, 'upload done!' );

            like( $res->content, qr/Linhas aceitas: 2/, '2 linhas no XLS' );

            ( $res, $c ) = ctx_request(
                POST '/api/variable/value_via_file',
                'Content-Type' => 'form-data',
                Content        => [
                    api_key   => 'test',
                    'arquivo' => ["$Bin/teste-upload.csv"],
                ]
            );
            ok( $res->is_success, 'OK' );
            is( $res->code, 200, 'upload done!' );

            like( $res->content, qr/Linhas aceitas: 4\\n"/, '4 linhas no CSV' );

            my @values = $schema->resultset('VariableValue')->search(
                undef,
                {
                    order_by => 'valid_from',
                    rows     => 2
                }
            )->all;

            is( $values[0]->valid_from->ymd, '2012-01-01', 'valid from ok' );
            is( $values[1]->valid_from->ymd, '2013-01-01', 'valid from ok' );

            is( $values[0]->value,  '0',          'value ok' );
            is( $values[1]->value,  '1',          'value ok' );
            is( $values[1]->source, 'outração', 'source ok' );

            is( $values[0]->observations, undef, 'observations ok' );
            is( $values[0]->source, 'isso eh uma fonte', 'source ok' );

            my @sources = $schema->resultset('Source')->search(
                undef,
                {
                    order_by => 'id'
                }
            )->all;
            is( scalar @sources, '5', 'tem as cinco fontes!' );
            is_deeply(
                [ map { $_->name } @sources ],
                [
                    'isso eh uma fonte',    # xlsx
                    'puntuação',          # xlsx
                    'segunda fonte',        # xlsx
                    'atenção',            # xls
                    'outração'            # csv
                ],
                'fontes ok'
            );

            ( $res, $c ) = ctx_request(
                POST '/api/variable/value_via_file',
                'Content-Type' => 'form-data',
                Content        => [
                    api_key   => 'test',
                    'arquivo' => ["$Bin/test-upload-invalid-data.xlsx"],
                ]
            );
            ok( $res->is_success, 'OK' );
            is( $res->code, 200, 'upload done!' );

            like( $res->content, qr/não é um número válido/, 'não é um número válido' );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
