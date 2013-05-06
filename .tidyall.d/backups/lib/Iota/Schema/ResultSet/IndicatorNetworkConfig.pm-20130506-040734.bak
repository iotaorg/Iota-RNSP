
package Iota::Schema::ResultSet::IndicatorNetworkConfig;

use namespace::autoclean;

use Moose;
extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use Iota::IndicatorFormula;

sub _build_verifier_scope_name { 'indicator.network_config' }

sub verifiers_specs {
    my $self = shift;
    return {
        upsert => Data::Verifier->new(
            profile => {
                indicator_id => { required => 1, type => 'Int' },
                network_id   => { required => 1, type => 'Int' },
                unfolded_in_home => { required => 1, type => 'Bool' },
            },
        ),
    };
}

sub action_specs {
    my $self = shift;
    return {
        upsert => sub {
            my %values = shift->valid_values;
            do { delete $values{$_} unless defined $values{$_} }
              for keys %values;
            return unless keys %values;

            my $var = $self->update_or_create( \%values );
            $var->discard_changes;
            return $var;
        }
    };
}

1;

