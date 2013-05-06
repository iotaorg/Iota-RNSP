
package Iota::Schema::ResultSet::IndicatorVariation;

use namespace::autoclean;

use Moose;
extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use Iota::IndicatorFormula;

sub _build_verifier_scope_name { 'indicator.variation' }

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            profile => {
                name         => { required => 1, type => 'Str' },
                indicator_id => { required => 1, type => 'Int' },
                order        => { required => 1, type => 'Int' },
                user_id      => { required => 1, type => 'Int' },
            },
        ),

        update => Data::Verifier->new(
            profile => {
                id    => { required => 1, type => 'Int' },
                name  => { required => 1, type => 'Str' },
                order => { required => 0, type => 'Int' },
            },
        ),

    };
}

sub action_specs {
    my $self = shift;
    return {
        create => sub {
            my %values = shift->valid_values;
            do { delete $values{$_} unless defined $values{$_} }
              for keys %values;
            return unless keys %values;

            my $var = $self->create( \%values );

            $var->discard_changes;
            return $var;
        },
        update => sub {
            my %values = shift->valid_values;

            do { delete $values{$_} unless defined $values{$_} }
              for keys %values;
            return unless keys %values;

            my $var = $self->find( delete $values{id} )->update( \%values );
            $var->discard_changes;
            return $var;
        },

    };
}

1;

