
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
                city_id => {
                    required => 0,
                    type     => 'Int',
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
                prefeito => { required => 0, type => 'Int',
                    post_check => sub {
                        my $r = shift;
                        my $city = $self->result_source->schema->resultset('City')->find({
                            id => $r->get_value('city_id')
                        });
                        return 1 unless $city;

                        return !defined $city->prefeito;
                    }
                },
                movimento => { required => 0, type => 'Int',
                    post_check => sub {
                        my $r = shift;
                        my $city = $self->result_source->schema->resultset('City')->find({
                            id => $r->get_value('city_id')
                        });
                        return 1 unless $city;

                        return !defined $city->movimento;
                    }
                },
            },
        ),

        update => Data::Verifier->new(
            profile => {
                id => {
                    required => 1,
                    type     => 'Str',
                },
                city_id => {
                    required => 0,
                    type     => 'Int',
                },
                movimento => {
                    required => 0, type => 'Int',
                    post_check => sub {
                        my $r = shift;
                        return 0 if $r->get_value('prefeito')  && $r->get_value('movimento');
                        return 1 unless defined $r->get_value('movimento');


                        my $city = $self->result_source->schema->resultset('City')->find({
                            id => $r->get_value('city_id')
                        });
                        return 1 unless $city;

                        return 1 if $r->get_value('movimento') eq '0';

                        my $mov = $city->movimento;
                        # se tem movimento, mas eh ele mesmo, libera
                        if ( $mov && $mov->user_id == $r->get_value('id') ) {
                            return 1
                        }

                        return defined $mov ? 0 : 1;
                    }
                },
                prefeito => {
                    required => 0, type => 'Int',
                    post_check => sub {
                        my $r = shift;

                        return 0 if $r->get_value('movimento') && $r->get_value('prefeito');
                        return 1 unless defined $r->get_value('prefeito');


                        my $city = $self->result_source->schema->resultset('City')->find({
                            id => $r->get_value('city_id')
                        });
                        return 1 unless $city;

                        return 1 if $r->get_value('prefeito') eq '0';

                        my $pref = $city->prefeito;
                        # se tem prefeito, mas eh ele mesmo, libera
                        if ( $pref && $pref->user_id == $r->get_value('id') ) {
                            return 1
                        }

                        return defined $pref ? 0 : 1;
                    }
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
                    required  => 0,
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

                        return $self->search( { email => $r->get_value('email') } )->count > 0;
                    }
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

            my $mov = delete $values{movimento};
            my $pref = delete $values{prefeito};
            my $user = $self->create( \%values );

            if ($role){
                $user->add_to_user_roles({
                role => {name => $role}
                });
            }


            if ($user->city_id && ($mov || $pref) ){
                $user->add_to_user_roles({
                    role => {name => '_movimento'}
                }) if $mov;

                $user->add_to_user_roles({
                    role => {name => '_prefeitura'}
                }) if $pref;
            }

            $user->discard_changes;
            return $user;
        },
        update => sub {
            my %values = shift->valid_values;
            delete $values{password_confirm};
            delete $values{password} unless $values{password};
            delete $values{city_id} unless $values{city_id};

            my $mov = delete $values{movimento};
            my $pref = delete $values{prefeito};

            my $user = $self->find( delete $values{id} );

            # se tem uma cidade antiga, e nao foi enviado o que fazer
            # troca para 'remover cargos' porque geralmente isso
            # que vai acontecer
            my $old_city = $user->city_id;
            if ($old_city && $values{city_id} && $old_city != $values{city_id}){
                $mov  = 0 unless defined $mov;
                $pref = 0 unless defined $pref;
            }

            $user->update( \%values );

            if ($user->city_id && (defined $mov || defined $pref) ){
                if (defined $mov){
                    if ($mov){
                        $user->add_to_user_roles({
                            role => {name => '_movimento'}
                        }) unless $user->movimento;
                    }else{
                        my $role = $self->result_source->schema->resultset('Role')->find({
                            name => '_movimento'
                        });
                        $user->remove_from_roles($role);
                    }
                }

                if (defined $pref){
                    if ($pref){
                        $user->add_to_user_roles({
                            role => {name => '_prefeitura'}
                        }) unless $user->prefeito;
                    }else{
                        my $role = $self->result_source->schema->resultset('Role')->find({
                            name => '_prefeitura'
                        });
                        $user->remove_from_roles($role);
                    }
                }
            }

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

