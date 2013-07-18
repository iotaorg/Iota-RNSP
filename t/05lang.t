use strict;
use warnings;

use Test::More;
use Test::Deep;

use I18N::AcceptLanguage;

my $supportedLanguages = [ ( 'pt-br', 'es' ) ];

my $pt = 'pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4';

my $acceptor = I18N::AcceptLanguage->new();
my $language = $acceptor->accepts( $pt, $supportedLanguages );
is( $language, 'pt-br', 'ok pt br' );

my $es = 'en-US,es;q=0.8,pt-BR;q=0.6,en;q=0.4';

$language = $acceptor->accepts( $es, $supportedLanguages );
is( $language, 'es', 'ok es' );

done_testing;

