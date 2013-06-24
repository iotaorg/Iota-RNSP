
package Iota::Schema::ResultSet::UserBestPratice;

use namespace::autoclean;

use Moose;

extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use Text2URI;
my $text2uri = Text2URI->new();
use Iota::Types qw /VariableType DataStr/;

sub _build_verifier_scope_name { 'best_pratice' }

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                user_id      => { required => 1, type => 'Int' },

                axis_id       => { required => 1, type => 'Int' },
                name          => { required => 1, type => 'Str' },
                description   => { required => 0, type => 'Str' },
                methodology   => { required => 0, type => 'Str' },
                goals         => { required => 0, type => 'Str' },
                schedule      => { required => 0, type => 'Str' },
                results       => { required => 0, type => 'Str' },
                contatcts     => { required => 0, type => 'Str' },
                sources       => { required => 0, type => 'Str' },
                tags          => { required => 0, type => 'Str' },
                institutions_involved => { required => 0, type => 'Str' },

            },
        ),

        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                id           => { required => 1, type => 'Int' },
                axis_id       => { required => 0, type => 'Int' },
                name          => { required => 0, type => 'Str' },
                name_url      => { required => 0, type => 'Str' },
                description   => { required => 0, type => 'Str' },
                methodology   => { required => 0, type => 'Str' },
                goals         => { required => 0, type => 'Str' },
                schedule      => { required => 0, type => 'Str' },
                results       => { required => 0, type => 'Str' },
                contatcts     => { required => 0, type => 'Str' },
                sources       => { required => 0, type => 'Str' },
                tags          => { required => 0, type => 'Str' },
                institutions_involved => { required => 0, type => 'Str' },

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

            my $var = $self->find( delete $values{id} )->update( \%values );
            $var->discard_changes;
            return $var;
        },

    };
}

1;

