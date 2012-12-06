
package RNSP::PCS::Schema::ResultSet::Axis;

use namespace::autoclean;

use Moose;
extends 'DBIx::Class::ResultSet';
with 'RNSP::PCS::Role::Verification';
with 'RNSP::PCS::Schema::Role::InflateAsHashRef';

use Data::Verifier;

sub _build_verifier_scope_name { 'axis' }

sub verifiers_specs {
    my $self = shift;
    return {};
}

sub action_specs {
    my $self = shift;
    return {};
}

1;

