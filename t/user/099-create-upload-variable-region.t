
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use File::Temp qw/ tempfile /;
use Text::CSV_XS;
use Catalyst::Test q(Iota);

use HTTP::Request::Common;
use Package::Stash;
use Path::Class qw(dir);
use Iota::TestOnly::Mock::AuthUser;
use JSON;

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

            my ( $res, $c ) = ctx_request(
                POST '/api/city/' . $city->id . '/region',
                [
                    api_key                          => 'test',
                    'city.region.create.name'        => 'a region',
                    'city.region.create.description' => 'with no description',
                ]
            );

            ok( $res->is_success, 'region created!' );
            is( $res->code, 201, 'region created!' );

            my $reg1_uri = $res->header('Location');
            my $reg1 = eval { from_json( $res->content ) };
            ok( $reg1->{id}, 'has id' );

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
            my $user_id = eval { from_json( $res->content ) };

            my ( $fh, $filename ) = tempfile( SUFFIX => '.csv' );
            my $csv = Text::CSV_XS->new( { binary => 1, eol => "\r\n" } )
              or die "Cannot use CSV: " . Text::CSV_XS->error_diag();

            $csv->print( $fh, [ 'ID da váriavel', 'Data', 'Valor', 'fonte', 'observacao', 'regiao id' ] );

            $csv->print( $fh, [ 19, '2010-01-01', '123', 'foobar', 'obs', $reg1->{id} ] );
            $csv->print( $fh, [ 19, '2011-01-01', '456', 'foobar', '222', $reg1->{id} ] );
            close $fh;

            $Iota::TestOnly::Mock::AuthUser::_id    = $user_id->{id};
            @Iota::TestOnly::Mock::AuthUser::_roles = qw/ user /;

            ( $res, $c ) = ctx_request(
                POST '/api/variable/value_via_file',
                'Content-Type' => 'form-data',
                Content        => [
                    api_key   => 'test',
                    'arquivo' => [$filename],
                ]
            );
            ok( $res->is_success, 'OK' );
            is( $res->code, 200, 'upload done!' );

            like( $res->content, qr/Linhas aceitas: 2\\n"/, '2 linhas no CSV' );

            my @sources = $schema->resultset('Source')->all;
            is( scalar @sources, '1', 'tem uma fonte!' );

            my @values = $schema->resultset('RegionVariableValue')->search( undef, { order_by => 'valid_from' } )->all;

            is( $values[0]->valid_from->ymd, '2010-01-01', 'valid from ok' );
            is( $values[1]->valid_from->ymd, '2011-01-01', 'valid from ok' );

            is( $values[0]->value, '123', 'value ok' );
            is( $values[1]->value, '456', 'value ok' );

            is( $values[0]->observations, 'obs', 'observations ok' );
            is( $values[1]->observations, '222', 'observations ok' );

            ( $res, $c ) = ctx_request( GET '/api/file' );
            ok( $res->is_success, 'OK' );
            is( $res->code, 200, 'list files done!' );

            my $files = eval { from_json( $res->content ) };
            my $x = quotemeta $files->{files}[0]{name};
            like( $filename, qr/$x/, 'file saved ' );

            ( $fh, $filename ) = tempfile( SUFFIX => '.csv' );
            $csv = Text::CSV_XS->new( { binary => 1, eol => "\r\n" } )
              or die "Cannot use CSV: " . Text::CSV_XS->error_diag();

            $csv->print( $fh, [ 'ID da váriavel', 'Data', 'Valor', 'fonte', 'observacao', 'regiao id' ] );
            $csv->print( $fh, [ 19, '2011-01-01', '456', 'foobar', 'obs', 'foobar' ] );

            close $fh;

            ( $res, $c ) = ctx_request(
                POST '/api/variable/value_via_file',
                'Content-Type' => 'form-data',
                Content        => [
                    api_key   => 'test',
                    'arquivo' => [$filename],
                ]
            );
            ok( $res->is_success, 'OK' );
            is( $res->code, 200, 'upload done!' );

            like( $res->content, qr/invalid region id/, 'invalid region id' );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
