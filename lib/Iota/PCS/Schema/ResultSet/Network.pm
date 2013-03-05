
package Iota::PCS::Schema::ResultSet::Network;

use namespace::autoclean;

use Moose;

extends 'DBIx::Class::ResultSet';
with 'Iota::PCS::Role::Verification';
with 'Iota::PCS::Schema::Role::InflateAsHashRef';

use Data::Verifier;

sub _build_verifier_scope_name { 'network' }

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            profile => {
                created_by => { required => 1, type => 'Int' },
                name       => { required => 1, type => 'Str' },
                name_url   => { required => 1, type => 'Str' },
                users_can_edit_value => { required => 0, type => 'Str' },
                users_can_edit_groups => { required => 0, type => 'Str' },
            },
        ),

        update => Data::Verifier->new(
            profile => {
                id       => { required => 1, type => 'Int' },
                name     => { required => 0, type => 'Str' },
                name_url => { required => 0, type => 'Str' },
                users_can_edit_value => { required => 0, type => 'Str' },
                users_can_edit_groups => { required => 0, type => 'Str' },
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

