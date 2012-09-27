
package RNSP::PCS::Schema::ResultSet::City;

use namespace::autoclean;

use Moose;
extends 'DBIx::Class::ResultSet';
with 'RNSP::PCS::Role::Verification';
with 'RNSP::PCS::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use JSON qw /encode_json/;

sub _build_verifier_scope_name {'city'}

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            profile => {
                name        => { required => 1, type => 'Str' },
                uf          => { required => 1, type => 'Str' },
                pais        => { required => 0, type => 'Str' },
                latitude    => { required => 0, type => 'Num' },
                longitude   => { required => 0, type => 'Num' },

            },
        ),

        update => Data::Verifier->new(
            profile => {
                id          => { required => 1, type => 'Int' },
                name        => { required => 0, type => 'Str' },
                uf          => { required => 0, type => 'Str' },
                pais        => { required => 0, type => 'Str' },
                latitude    => { required => 0, type => 'Num' },
                longitude   => { required => 0, type => 'Num' },

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

