package Iota::Schema::ResultSet::User;

use namespace::autoclean;

use Moose;
extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use JSON qw /encode_json/;
use String::Random;
use MooseX::Types::Email qw/EmailAddress/;

sub _build_verifier_scope_name { 'user' }

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
                    required => 1,
                    type     => 'Str',

                    post_check => sub {
                        my $r = shift;
                        return $r->get_value('role') =~ /^(admin|user)$/;
                    },

                },
                network_id => {
                    required   => 1,
                    type       => 'Int',
                    post_check => sub {
                        my $r = shift;

                        my $net =
                          $self->result_source->schema->resultset('Network')
                          ->find( { id => $r->get_value('network_id') } );
                        return 0 unless $net;

                        if ( $r->get_value('role') eq 'user' ) {
                            my $city =
                              $self->result_source->schema->resultset('City')
                              ->find( { id => $r->get_value('city_id') } );
                            return 0 unless $city;

                            my $exists = $self->search(
                                {
                                    city_id    => $r->get_value('city_id'),
                                    network_id => $r->get_value('network_id'),
                                }
                            )->count;

                            return 0 if $exists;

                        }

                        return 1;
                      }
                },

                nome_responsavel_cadastro => { required => 0, type => 'Str' },
                estado                    => { required => 0, type => 'Str' },
                telefone                  => { required => 0, type => 'Str' },
                email_contato             => { required => 0, type => 'Str' },
                telefone_contato          => { required => 0, type => 'Str' },
                cidade                    => { required => 0, type => 'Str' },
                bairro                    => { required => 0, type => 'Str' },
                cep                       => { required => 0, type => 'Str' },
                endereco                  => { required => 0, type => 'Str' },
                city_summary              => { required => 0, type => 'Str' },
            },
        ),

        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                id => {
                    required => 1,
                    type     => 'Str',
                },
                city_id => {
                    required   => 0,
                    type       => 'Int',
                    post_check => sub {
                        my $r = shift;
                        return 1;# TODO arrumar isso

                        # cidade precisa existir
                        my $city =
                          $self->result_source->schema->resultset('City')->find( { id => $r->get_value('city_id') } );
                        return 0 unless $city;

                        # eu preciso existir!
                        my $me = $self->find( $r->get_value('id') );
                        return 0 unless $me;

                        # se nao tem rede, pode ir pra qualquer cidade.
                        return 1 unless $me->network_id;

                        my $roles = join( ' ', map { $_->name } $me->roles );

                        if ( $roles =~ /\buser\b/ ) {

                            my $exists = $self->search(
                                {
                                    city_id    => $city->id,
                                    network_id => $r->get_value('network_id') || $me->network_id,
                                }
                            )->count;

                            return 0 if $exists;

                        }

                        return 1;
                      }
                },
                network_id => {
                    required   => 0,
                    type       => 'Int',
                    post_check => sub {
                        my $r = shift;

                        # rede precisa existir
                        my $net =
                          $self->result_source->schema->resultset('Network')
                          ->find( { id => $r->get_value('network_id') } );
                        return 0 unless $net;

                        # eu preciso existir!
                        my $me = $self->find( $r->get_value('id') );
                        return 0 unless $me;

                        # se nao tem cidade, pode trocar de rede !
                        my $city_id = $r->get_value('city_id') || $me->city_id;
                        return 1 unless $city_id;

                        my $roles = join( ' ', map { $_->name } $me->roles );

                        if ( $roles =~ /\buser\b/ ) {

                            # pra ser usuario, precisa ser de alguma cidade
                            my $city = $self->result_source->schema->resultset('City')->find($city_id);
                            return 0 unless $city;

                            my $exists = $self->search(
                                {
                                    city_id    => $city_id,
                                    network_id => $r->get_value('network_id'),
                                }
                            )->count;

                            return 0 if $exists;

                        }

                        return 1;
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

                nome_responsavel_cadastro => { required => 0, type => 'Str' },
                estado                    => { required => 0, type => 'Str' },
                telefone                  => { required => 0, type => 'Str' },
                email_contato             => { required => 0, type => 'Str' },
                telefone_contato          => { required => 0, type => 'Str' },
                cidade                    => { required => 0, type => 'Str' },
                bairro                    => { required => 0, type => 'Str' },
                cep                       => { required => 0, type => 'Str' },
                endereco                  => { required => 0, type => 'Str' },
                city_summary              => { required => 0, type => 'Str' },
                active                    => { required => 0, type => 'Bool' },
            },
        ),

        login => Data::Verifier->new(
            filters => [qw(trim)],
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
            filters => [qw(trim)],
            profile => {
                secret_key => {
                    required   => 1,
                    type       => 'Str',
                    post_check => sub {
                        my $r     = shift;
                        my $where = {
                            secret_key  => $r->get_value('secret_key'),
                            reseted_at  => undef,
                            valid_until => { '>=' => \'NOW()' }
                        };

                        # email precisa conferir com o do dono da chave
                        my $rs =
                          $self->search($where)->search_related( 'id_user', { email => $r->get_value('email') } );
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
            filters => [qw(trim)],
            profile => {
                email => {
                    required   => 1,
                    type       => 'Str',
                    post_check => sub {
                        my $r    = shift;
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
        login  => sub { 1 },
        create => sub {
            my %values = shift->valid_values;
            delete $values{password_confirm};
            my $role = delete $values{role};

            my $user = $self->create( \%values, active => 1 );

            $user->add_to_user_roles( { role => { name => $role } } );

            $user->discard_changes;
            return $user;
        },
        update => sub {
            my %values = shift->valid_values;
            delete $values{password_confirm};
            delete $values{password} unless $values{password};
            delete $values{city_id}  unless $values{city_id};

            delete $values{active} unless $values{active};

            do { delete $values{$_} unless defined $values{$_} }
              for keys %values;
            return unless keys %values;

            my $user = $self->find( delete $values{id} );

            $user->update( \%values );

            $user->discard_changes;
            return $user;
        },
        reset_password => sub {
            my %values = shift->valid_values;

            my $user = $self->find( { email => $values{email} } )->update( { password => $values{password} } );

            $user->user_forgotten_passwords->find( { secret_key => $values{secret_key} } )
              ->update( { reseted_at => \'NOW()' } );

            return 1;
        },
        forgot_password => sub {
            my %values = shift->valid_values;

            my $user = $self->search( { email => $values{email} } )->first;
            my %user_attrs = $user->get_inflated_columns;
            delete $user_attrs{password};

            my $secret_key = new String::Random->randregex('[A-Za-z0-9]{40}');

            my $result = $user->user_forgotten_passwords->create(
                {
                    id_user    => $user->id,
                    secret_key => $secret_key
                }
            );

            $user_attrs{secret_key} = $secret_key;

            my $queue = $self->result_source->schema->resultset('EmailsQueue');
            $queue->create(
                {
                    to        => $user->email,
                    subject   => 'Recuperar senha perdida [% name %]',
                    template  => 'forgot_password.tt',
                    variables => encode_json( { map { $_ => $user_attrs{$_} } qw / name email secret_key / } ),
                    sent      => 0
                }
            );

            return 1;
        },
    };
}

sub with_city {
    my ($self) = @_;
    return $self->search( { city_id => { '!=' => undef } } );
}

1;
