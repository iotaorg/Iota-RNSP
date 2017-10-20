use common::sense;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Iota::Test::Further;

use Catalyst::Test q(Iota);

use HTTP::Request::Common;
use Package::Stash;
use Iota::IndicatorFormula;

use Iota::TestOnly::Mock::AuthUser;

my $schema = Iota->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::TestOnly::Mock::AuthUser->new;

$Iota::TestOnly::Mock::AuthUser::_id    = 2;
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

db_transaction {

    my $var1 = &new_var( 'int', 'weekly' );
    my $var2 = &new_var( 'int', 'weekly' );
    my $var3 = &new_var( 'num', 'yearly' );
    my $var4 = &new_var( 'num', 'yearly' );
    my $var5 = &new_var( 'str', 'yearly' );
    my $var6 = &new_var( 'str', 'yearly' );
    my $f = new Iota::IndicatorFormula( formula => "\$$var1 + \$$var2", schema => $schema );

    my @expected = ( $var1, $var2 );
    is( ( join ',', sort $f->variables ), ( join ',', sort @expected ), 'same variables!' );

    is(
        $f->evaluate(
            "$var1" => 4,
            "$var2" => 7
        ),
        11,
        'sum with variables looks good!'
    );

    $f = new Iota::IndicatorFormula( formula => "sqrt(\$$var3 + \$$var4)", schema => $schema );
    is(
        $f->evaluate(
            "$var3" => 5.32,
            "$var4" => 19.68
        ),
        5,
        'sqrt with sum of floats look good!'
    );

    $f = new Iota::IndicatorFormula(
        formula => "-5 + sqrt(\$$var1 / (\$$var2 * \$$var2)) + 1",
        schema  => $schema
    );
    is(
        $f->evaluate(
            "$var1" => 625,
            "$var2" => 5
        ),
        1,
        '"-5 + sqrt(\$$var1 / (\$$var2 * \$$var2)) + 1" OK!'
    );

    eval { new Iota::IndicatorFormula( formula => "15)", schema => $schema ) };
    like( $@, qr/Parse error/, 'error 001' );

    #eval{new Iota::IndicatorFormula(formula => "\$$var1 + \$$var5", schema => $schema)};
    #like($@, qr/string/, 'error 004');

    eval { new Iota::IndicatorFormula( formula => "(22", schema => $schema ) };
    like( $@, qr/ClosingParen/, 'error 002' );

    eval { new Iota::IndicatorFormula( formula => '"ABC" . 2345', schema => $schema ) };
    like( $@, qr/No token matched input text/, 'error 003' );

    $f = new Iota::IndicatorFormula( formula => "CONCATENAR \$$var5 \$$var6", schema => $schema );
    is(
        $f->evaluate(
            "$var5" => 'renato',
            "$var6" => 'cron'
        ),
        'renato cron',
        'CONCATENAR funcionando!'
    );

    # soma em periodos diferentes
    eval { new Iota::IndicatorFormula( formula => "\$$var1 + \$$var3", schema => $schema ) };
    like( $@, qr/variables with mixed period not allowed/, 'variables with mixed period not allowed!' );

};

done_testing;
