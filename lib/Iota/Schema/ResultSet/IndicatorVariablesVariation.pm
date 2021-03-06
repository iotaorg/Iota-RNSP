package Iota::Schema::ResultSet::IndicatorVariablesVariation;

use namespace::autoclean;

use Moose;
extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use Iota::IndicatorFormula;

sub _build_verifier_scope_name { 'indicator.variables_variation' }

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                name         => { required => 1, type => 'Str' },
                type         => { required => 0, type => 'Str' },
                explanation  => { required => 0, type => 'Str' },
                indicator_id => { required => 1, type => 'Int' },
            },
        ),

        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                id          => { required => 1, type => 'Int' },
                name        => { required => 1, type => 'Str' },
                type        => { required => 0, type => 'Str' },
                explanation => { required => 0, type => 'Str' },
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

            my $var = $self->find( delete $values{id} );

            if ( exists $values{summarization_method} && $var->summarization_method ne $values{summarization_method} ) {
                $self->result_source->schema->f_compute_all_upper_regions();
            }

            $var->update( \%values );
            $var->discard_changes;
            return $var;
        },

    };
}

1;

