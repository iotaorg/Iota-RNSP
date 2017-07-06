use strict;
use warnings;
use utf8;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Config::General;
use Template;

use Encode;
use JSON qw / decode_json /;

use Iota;
my $schema = Iota->model('DB');

use Iota::IndicatorFormula;

my @indicadores = $schema->resultset('Indicator')->all;

foreach my $ind (@indicadores) {

    my $formula = Iota::IndicatorFormula->new(
        formula => $ind->formula,
        schema  => $schema
    );

    $ind->update( { formula_human => $formula->as_human} );
=pod
    $ind->indicator_variables->delete;
    $ind->add_to_indicator_variables( { variable_id => $_ } ) for $formula->variables;

    if ( $formula->_variable_count ) {
        my $anyvar = $ind->indicator_variables->next->variable;
        $ind->period( $anyvar->period );
        $ind->variable_type( $anyvar->type );
    }
    else {
        $ind->period('yearly');
        $ind->variable_type('int');
    }
=cut


}

