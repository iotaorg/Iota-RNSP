package Iota::Schema::ResultSet::EndUserIndicator;

use namespace::autoclean;

use Moose;

extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Data::Verifier;

use Iota::Types qw /VariableType DataStr/;

use MooseX::Types::Email qw/EmailAddress/;

sub _build_verifier_scope_name { 'end_user_indicator' }

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                indicator_id => {
                    required => 1,
                    type     => 'Int',
                },
                network_id => {
                    required => 1,
                    type     => 'Int',
                },
                end_user_id => {
                    required => 1,
                    type     => 'Int',
                },
            },
        ),

    };
}

sub action_specs {
    my $self = shift;
    return {
        create => sub {
            my %values = shift->valid_values;

            $values{all_users} = 1;

            my $var = $self->create( \%values );

            return $var;
        },

    };
}

1;

