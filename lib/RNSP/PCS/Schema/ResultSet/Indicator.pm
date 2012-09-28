
package RNSP::PCS::Schema::ResultSet::Indicator;

use namespace::autoclean;

use Moose;
extends 'DBIx::Class::ResultSet';
with 'RNSP::PCS::Role::Verification';
with 'RNSP::PCS::Schema::Role::InflateAsHashRef';

use Data::Verifier;


sub _build_verifier_scope_name {'indicator'}

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            profile => {
                name        => { required => 1, type => 'Str' },
                formula     => { required => 1, type => 'Str' }, # check Math::Expression::Evaluator
                goal        => { required => 1, type => 'Num' },
                axis        => { required => 1, type => 'Str' },
                user_id     => { required => 1, type => 'Int' },
                source       => { required => 0, type => 'Str' },
                explanation  => { required => 0, type => 'Str' },

            },
        ),

        update => Data::Verifier->new(
            profile => {
                id          => { required => 1, type => 'Int' },
                name        => { required => 0, type => 'Str' },
                formula     => { required => 0, type => 'Str' },
                goal        => { required => 0, type => 'Num' },
                axis        => { required => 0, type => 'Str' },
                source       => { required => 0, type => 'Str' },
                explanation  => { required => 0, type => 'Str' },
            },
        ),



    };
}

sub action_specs {
    my $self = shift;
    return {
        create => sub {
            my %values = shift->valid_values;
            do { delete $values{$_} unless defined $values{$_}} for keys %values;
            return unless keys %values;

            my $var = $self->create( \%values );

            $var->discard_changes;
            return $var;
        },
        update => sub {
            my %values = shift->valid_values;

            do { delete $values{$_} unless defined $values{$_}} for keys %values;
            return unless keys %values;

            my $var = $self->find( delete $values{id} )->update( \%values );
            $var->discard_changes;
            return $var;
        },

    };
}

1;

