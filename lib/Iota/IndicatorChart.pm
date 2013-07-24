package Iota::IndicatorChart;

use Moose;
with 'MooseX::Traits';
has '+_trait_namespace' => ( default => 'Iota::IndicatorChart' );

use Iota::Schema::Result::Indicator;

has indicator => (
    is       => 'ro',
    isa      => 'Iota::Schema::Result::Indicator',
    required => 1
);

has schema => (
    is       => 'ro',
    isa      => 'Any',
    required => 1
);

has _data => (
    is       => 'rw',
    isa      => 'HashRef',
    init_arg => undef
);

sub read_values {
    die 'you need start this with a trait!';
}

sub data {
    my ( $self, %options ) = @_;
    $self->read_values(%options);

    return $self->_data;
}

1;
