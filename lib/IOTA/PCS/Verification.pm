package IOTA::PCS::Role::Verification;
use namespace::autoclean;
use Moose::Role;

use IOTA::PCS::Data::Visitor;

has verifiers => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

has actions => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

has _visitor => (
    is      => 'ro',
    isa     => 'Mu::Data::Visitor',
    lazy    => 1,
    default => sub { Mu::Data::Visitor->new }
);

has verifier_scope_name => (
    is         => 'ro',
    lazy_build => 1,
    isa        => 'Str'
);

requires 'verifiers_specs';
requires 'action_specs';
requires '_build_verifier_scope_name';

sub _build_verifiers {
    my $self = shift;
    return $self->_build_map_from_specs( $self->verifiers_specs );
}

sub _build_actions {
    my $self = shift;
    return $self->_build_map_from_specs( $self->action_specs );
}

sub _build_map_from_specs {
    my ( $self, $specs ) = @_;
    $self->_visitor->visit( { $self->verifier_scope_name => $specs } );
    my $final_specs = $self->_visitor->final_value;
    $self->_visitor->_clear_final_value;
    return +{
        map {
            my $top = $_;
            map { $top . '.' . $_ => $final_specs->{$top}->{$_} }
                keys %{ $final_specs->{$top} }
            }
            keys %$final_specs
    };
}

1;
