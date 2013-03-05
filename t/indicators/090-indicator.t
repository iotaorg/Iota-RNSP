
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(Iota);

use HTTP::Request::Common;
use Package::Stash;
use Iota::IndicatorFormula;

use Iota::TestOnly::Mock::AuthUser;
my $seq = 0;
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

            my $var1 = &new_var('int', 'weekly');
            my $var2 = &new_var('int', 'weekly');
            my $var3 = &new_var('num', 'yearly');
            my $var4 = &new_var('num', 'yearly');
            my $var5 = &new_var('str', 'yearly');
            my $var6 = &new_var('str', 'yearly');
            my $f = new Iota::IndicatorFormula(formula => "\$$var1 + \$$var2", schema => $schema);

            my @expected = ($var1, $var2);
            is((join ',', sort $f->variables), (join ',', sort @expected), 'same variables!');

            is($f->evaluate(
                "$var1" => 4,
                "$var2" => 7
            ), 11, 'sum with variables looks good!');


            $f = new Iota::IndicatorFormula(formula => "sqrt(\$$var3 + \$$var4)", schema => $schema);
            is($f->evaluate(
                "$var3" => 5.32,
                "$var4" => 19.68
            ), 5, 'sqrt with sum of floats look good!');

            $f = new Iota::IndicatorFormula(formula => "-5 + sqrt(\$$var1 / (\$$var2 * \$$var2)) + 1", schema => $schema);
            is($f->evaluate(
                "$var1" => 625,
                "$var2" => 5
            ), 1, '"-5 + sqrt(\$$var1 / (\$$var2 * \$$var2)) + 1" OK!');

            eval{new Iota::IndicatorFormula(formula => "15)", schema => $schema)};
            like($@, qr/Parse error/, 'error 001');

            #eval{new Iota::IndicatorFormula(formula => "\$$var1 + \$$var5", schema => $schema)};
            #like($@, qr/string/, 'error 004');

            eval{new Iota::IndicatorFormula(formula => "(22", schema => $schema)};
            like($@, qr/ClosingParen/, 'error 002');

            eval{new Iota::IndicatorFormula(formula => '"ABC" . 2345', schema => $schema)};
            like($@, qr/No token matched input text/, 'error 003');

            $f = new Iota::IndicatorFormula(formula => "CONCATENAR \$$var5 \$$var6", schema => $schema);
            is($f->evaluate(
                "$var5" => 'renato',
                "$var6" => 'cron'
            ), 'renato cron', 'CONCATENAR funcionando!');

            # soma em periodos diferentes
            eval{new Iota::IndicatorFormula(formula => "\$$var1 + \$$var3", schema => $schema)};
            like($@, qr/variables with mixed period not allowed/, 'variables with mixed period not allowed!');


            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;


use JSON qw(from_json);
sub new_var {
    my $type = shift;
    my $period = shift;
    my ( $res, $c ) = ctx_request(
        POST '/api/variable',
        [   api_key                        => 'test',
            'variable.create.name'         => 'Foo Bar'.$seq++,
            'variable.create.cognomen'     => 'foobar'.$seq++,
            'variable.create.explanation'  => 'a foo with bar'.$seq++,
            'variable.create.type'         => $type,
            'variable.create.period'       => $period||'week',
            'variable.create.source'       => 'God',
        ]
    );
    if ($res->code == 201){
        my $xx = eval{from_json( $res->content )};
        return $xx->{id};
    }else{
        die('fail to create new var: ' . $res->code);
    }
}