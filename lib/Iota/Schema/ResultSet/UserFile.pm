
package Iota::Schema::ResultSet::UserFile;

use namespace::autoclean;

use Moose;

extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use Iota::Types qw /VariableType DataStr/;

sub _build_verifier_scope_name { 'user.file' }

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                user_id => { required => 1, type => 'Int' },

                class_name   => { required => 1, type => 'Str' },
                public_url   => { required => 1, type => 'Str' },
                private_path => { required => 1, type => 'Str' },

                hide_listing => { required => 1, type => 'Bool' },
                description  => { required => 0, type => 'Str' },
                public_name  => { required => 0, type => 'Str' },
            },
        ),

        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                id => { required => 1, type => 'Int' },

                hide_listing => { required => 0, type => 'Bool' },
                description  => { required => 0, type => 'Str' },
                public_name  => { required => 0, type => 'Str' },
                class_name   => { required => 0, type => 'Str' },
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

