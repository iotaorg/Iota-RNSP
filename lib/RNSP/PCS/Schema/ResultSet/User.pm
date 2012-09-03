
package RNSP::PCS::Schema::ResultSet::User;

use namespace::autoclean;

use Moose;
extends 'DBIx::Class::ResultSet';
with 'RNSP::PCS::Role::Verification';
with 'RNSP::PCS::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use JSON qw /encode_json/;
use String::Random;
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

                },
                password => {
                    required => 1,
                    type     => 'Str',
                },
            }
        ),

        reset_password => Data::Verifier->new(
            profile => {
                secret_key => {
                    required => 1,
                    type     => 'Str',
                    post_check => sub {
                        my $r = shift;
                        my $where = {
                        secret_key => $r->get_value('secret_key'),
                        reseted_at => undef,
                        valid_until => { '>=' =>  \'NOW()' }
                        };
                        # email precisa conferir com o do dono da chave
                        my $rs = $self->search($where)->search_related('id_user', {email => $r->get_value('email')  } );
                        return $rs->count > 0;
                    }
                },
                email => {
                    required   => 1,
                    type       => EmailAddress,
                    post_check => sub {
                        #my $r = shift;
                        #return 0
                        #if defined $self->find( { email => $r->get_value('email') } );
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
        forgot_password => Data::Verifier->new(
            profile => {
                email => {
                    required   => 1,
                    type       => 'Str',
                    post_check => sub {
                        my $r = shift;
                        my $user = $self;
                        my $qtde = $user->search( { email => $r->get_value('email') } )->count;
                        return $qtde >= 1;
                    }
                },
            },
        ),

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
        reset_password => sub {
            my %values = shift->valid_values;

            my $user = $self->
                find( { email => $values{email} } )->
                update( { password => $values{password} } );

            $user->user_forgotten_passwords->find({secret_key => $values{secret_key}})->update( { reseted_at => \'NOW()' } );


            return 1;
        },
        forgot_password => sub {
            my %values = shift->valid_values;

            my $user = $self->search( { email => $values{email} } )->first;
            my %user_attrs = $user->get_inflated_columns;
            delete $user_attrs{password};

            my $secret_key = new String::Random->randregex('[A-Za-z0-9]{40}');

            my $result = $user->user_forgotten_passwords->create( {
                id_user => $user->id,
                secret_key => $secret_key
            } );

            $user_attrs{secret_key} = $secret_key;

            my $queue = $self->result_source->schema->resultset('EmailsQueue');
            $queue->create({
                to        => $user->email,
                subject   => 'Recuperar senha perdida [% name %]',
                template  => 'forgot_password.tt',
                variables => encode_json( { map { $_ => $user_attrs{$_} } qw / name email secret_key / } ),
                sent      => 0
            });

            return 1;
        },
    };
}

1;

