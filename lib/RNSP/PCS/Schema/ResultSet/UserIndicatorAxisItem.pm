
package RNSP::PCS::Schema::ResultSet::UserIndicatorAxisItem;

use namespace::autoclean;

use Moose;
extends 'DBIx::Class::ResultSet';
with 'RNSP::PCS::Role::Verification';
with 'RNSP::PCS::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use RNSP::IndicatorFormula;

sub _build_verifier_scope_name { 'user_indicator_axis_item' }

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            profile => {
                indicator_id           => { required => 1, type => 'Int' },
                user_indicator_axis_id => { required => 1, type => 'Int' },
                position               => { required => 0, type => 'Int' },
            },
        ),

        update => Data::Verifier->new(
            profile => {
                id       => { required => 1, type => 'Int' },
                position => { required => 1, type => 'Int' },
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

