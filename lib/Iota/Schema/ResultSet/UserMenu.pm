
package Iota::Schema::ResultSet::UserMenu;

use namespace::autoclean;

use Moose;

extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use Text2URI;
my $text2uri = Text2URI->new();    # tem lazy la, don't worry

sub _build_verifier_scope_name { 'menu' }

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            profile => {
                user_id      => { required => 1, type => 'Str' },
                page_id      => { required => 1, type => 'Str' },
                title        => { required => 1, type => 'Str' },
                position     => { required => 0, type => 'Int' },
            },
        ),

        update => Data::Verifier->new(
            profile => {
                id           => { required => 1, type => 'Int' },
                user_id      => { required => 0, type => 'Str' },
                page_id      => { required => 0, type => 'Str' },
                title        => { required => 0, type => 'Str' },
                position     => { required => 0, type => 'Int' },
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

