
package Iota::Schema::ResultSet::State;

use namespace::autoclean;

use Moose;

extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use Text2URI;
my $text2uri = Text2URI->new();    # tem lazy la, don't worry

sub _build_verifier_scope_name { 'state' }

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                name       => { required => 1, type => 'Str' },
                uf         => { required => 1, type => 'Str' },
                country_id => { required => 1, type => 'Int' },
                created_by => { required => 1, type => 'Int' },
            },
        ),

        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                id         => { required => 1, type => 'Int' },
                name       => { required => 1, type => 'Str' },
                uf         => { required => 0, type => 'Str' },
                country_id => { required => 0, type => 'Int' },
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

            $values{uf} = uc $values{uf};

            $values{name_url} = uc $text2uri->translate( $values{uf} );

            my $var = $self->create( \%values );

            $var->discard_changes;
            return $var;
        },
        update => sub {
            my %values = shift->valid_values;

            do { delete $values{$_} unless defined $values{$_} }
              for keys %values;
            return unless keys %values;

            $values{uf} = uc $values{uf} if exists $values{uf};

            $values{name_url} = uc $text2uri->translate( $values{uf} ) if exists $values{uf} && $values{uf};

            my $var = $self->find( delete $values{id} )->update( \%values );
            $var->discard_changes;

            $var->cities->update( { uf => uc $var->name_url } );

            return $var;
        },

    };
}

1;

