
package RNSP::PCS::Schema::ResultSet::User;

use namespace::autoclean;

use Moose;
extends 'DBIx::Class::ResultSet';
with 'RNSP::PCS::Role::Verification';
with 'RNSP::PCS::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use MooseX::Types::Email qw/EmailAddress/;

sub _build_verifier_scope_name {'user'}

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
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
                role => {
                    required => 0,
                    type     => 'Str',
                },
            },
        ),

        update => Data::Verifier->new(
            profile => {
                id => {
                    required => 1,
                    type     => 'Str',
                },

                name => {
                    required => 1,
                    type     => 'Str',
                },
                email => {
                    required   => 1,
                    type       => EmailAddress,
                    post_check => sub {
                        my $r = shift;
                        if ( my $existing_user = $self->find( { email => $r->get_value('email') } ) ) {
                            return $existing_user->id == $r->get_value('id');
                        }
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

        login => Data::Verifier->new(
            profile => {
                email => {
                    required   => 1,
                    type       => EmailAddress,
                    post_check => sub {
                        my $r = shift;
                        return defined $self->find( { email => $r->get_value('email') } );
                        }
                },
                password => {
                    required => 1,
                    type     => 'Str',
                },
            }
        )
    };
}

sub action_specs {
    my $self = shift;
    return {
        login  => sub {1},
        create => sub {
            my %values = shift->valid_values;
            delete $values{password_confirm};
            my $role = delete $values{role};

            my $user = $self->create( \%values );
            if ($role){
                $user->add_to_user_roles({
                role => {name => $role}
                });
            }


            $user->discard_changes;
            return $user;
        },
        update => sub {
            my %values = shift->valid_values;
            delete $values{password_confirm};
            my $user = $self->find( delete $values{id} )->update( \%values );
            $user->discard_changes;
            return $user;
        },
    };
}

1;

