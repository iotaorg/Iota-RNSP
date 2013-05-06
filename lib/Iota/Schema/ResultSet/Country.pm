
package Iota::Schema::ResultSet::Country;

use namespace::autoclean;

use Moose;

extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use Text2URI;
my $text2uri = Text2URI->new();    # tem lazy la, don't worry

sub _build_verifier_scope_name { 'country' }

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            profile => {
                name       => { required => 1, type => 'Str' },
                name_url   => { required => 0, type => 'Str' },
                created_by => { required => 1, type => 'Int' },
            },
        ),

        update => Data::Verifier->new(
            profile => {
                id       => { required => 1, type => 'Int' },
                name     => { required => 1, type => 'Str' },
                name_url => { required => 0, type => 'Str' },
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

            $values{name_url} = $text2uri->translate( $values{name} ) unless $values{name_url};

            my $var = $self->create( \%values );

            $var->discard_changes;
            return $var;
        },
        update => sub {
            my %values = shift->valid_values;

            do { delete $values{$_} unless defined $values{$_} }
              for keys %values;
            return unless keys %values;

            $values{name_url} = $text2uri->translate( $values{name} ) unless $values{name_url};

            my $var = $self->find( delete $values{id} )->update( \%values );
            $var->discard_changes;

            $var->cities->update( { pais => $var->name_url } );

            return $var;
        },

    };
}

1;

