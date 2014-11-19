
package Iota::Schema::ResultSet::UserRegion;

use namespace::autoclean;

use Moose;

extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use Iota::Types qw /VariableType DataStr/;

sub _build_verifier_scope_name { 'user.region' }

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                user_id => { required => 1, type => 'Int' },

                depth_level => {
                    required   => 1,
                    type       => 'Int',
                    post_check => sub {
                        my $r   = shift;
                        my $row = $self->result_source->schema->resultset('UserRegion')->find(
                            {
                                depth_level => $r->get_value('depth_level'),
                                user_id     => $r->get_value('user_id')
                            }
                        );
                        return !defined $row;
                    }
                },
                region_classification_name => { required => 1, type => 'Str' },
            },
        ),

        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                id => { required => 1, type => 'Int' },

                region_classification_name => { required => 0, type => 'Str' },
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

