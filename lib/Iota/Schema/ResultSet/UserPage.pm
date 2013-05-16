
package Iota::Schema::ResultSet::UserPage;

use namespace::autoclean;

use Moose;

extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use Text2URI;
my $text2uri = Text2URI->new();    # tem lazy la, don't worry
use Iota::Types qw /VariableType DataStr/;

sub _build_verifier_scope_name { 'page' }

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                user_id      => { required => 1, type => 'Str' },
                published_at => { required => 0, type => DataStr },
                title        => { required => 1, type => 'Str' },
                title_url    => { required => 0, type => 'Str' },
                content      => { required => 1, type => 'Str' },
            },
        ),

        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                id           => { required => 1, type => 'Int' },
                user_id      => { required => 0, type => 'Str' },
                published_at => { required => 0, type => DataStr },
                title        => { required => 1, type => 'Str' },
                title_url    => { required => 0, type => 'Str' },
                content      => { required => 1, type => 'Str' },
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

            $values{title_url} = $text2uri->translate( $values{title} ) unless $values{title_url};

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

