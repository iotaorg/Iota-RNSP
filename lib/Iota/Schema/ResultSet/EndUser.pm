package Iota::Schema::ResultSet::EndUser;

use namespace::autoclean;

use Moose;

extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Data::Verifier;

use Iota::Types qw /VariableType DataStr/;

use MooseX::Types::Email qw/EmailAddress/;

sub _build_verifier_scope_name { 'end_user' }

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                name => {
                    required => 1,
                    type     => 'Str',
                },
                email => {
                    required   => 1,
                    type       => EmailAddress,
                    post_check => sub {
                        my $r = shift;
                        return 0
                          if defined $self->find( { email => $r->get_value('email') } );
                        return 1;
                      }
                },
                password => {
                    required  => 1,
                    type      => 'Str',
                    dependent => {
                        password_confirm => {
                            required => 1,
                            type     => 'Str',
                        },
                    },
                    post_check => sub {
                        my $r = shift;
                        return $r->get_value('password') eq $r->get_value('password_confirm');
                    },
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

            do { delete $values{$_} unless defined $values{$_} }
              for keys %values;
            return unless keys %values;
            delete $values{password_confirm};

            my $var = $self->create( \%values );

            $var->discard_changes;
            return $var;
        },

    };
}

1;

