package RNSP::IndicatorChart;

use Moose;
with 'MooseX::Traits';
has '+_trait_namespace' => ( default => 'RNSP::IndicatorChart' );


use RNSP::PCS::Schema::Result::Indicator;
use RNSP::IndicatorFormula;

has indicator => (
    is         => 'ro',
    isa        => 'RNSP::PCS::Schema::Result::Indicator',
    required   => 1
);


has indicator_formula => (
    is         => 'ro',
    isa        => 'RNSP::IndicatorFormula',
    lazy       => 1,
    default    => sub {
        my ($self) = @_;
        new RNSP::IndicatorFormula(formula => $self->indicator->formula, schema => $self->schema);
    }
);

has variables => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy       => 1,
    default    => sub { [$_[0]->indicator_formula->variables] }
);

has schema => (
    is         => 'ro',
    isa        => 'Any',
    required   => 1
);

has user_id => (
    is         => 'rw',
    isa        => 'Int',
    required   => 1
);

has _data => (
    is         => 'rw',
    isa         => 'HashRef',
    init_arg   => undef
);

sub read_values {
    die 'you need start this with a trait!'
}

sub data {
    my ($self, %options) = @_;
    $self->read_values(%options);

    return $self->_data;
}




1;
