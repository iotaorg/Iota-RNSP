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
                cur_lang => {
                    required => 0,
                    type     => 'Str',
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
                                    city_id      => $r->get_value('city_id'),
                                    institute_id => $net->institute_id,
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

                can_create_indicators => { required => 0, type => 'Bool' },
                regions_enabled       => { required => 0, type => 'Bool' },
            },
        ),

        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                id => {
                    required => 1,
                    type     => 'Str',
                },
                cur_lang => {
                    required => 0,
                    type     => 'Str',
                },
                city_id => {
                    required   => 0,
                    type       => 'Int',
                    post_check => sub {
                        my $r = shift;

                        # cidade precisa existir
                        my $city =
                          $self->result_source->schema->resultset('City')->find( { id => $r->get_value('city_id') } );
                        return 0 unless $city;

                        # eu preciso existir!
                        my $me = $self->find( $r->get_value('id') );
                        return 0 unless $me;

                        my $institute_id = $me->institute_id;

                        my $network_ids = $r->get_value('network_ids');

                        # deixa o validate do networks_ids se virar sozinho!
                        if ( $network_ids ne 'DO_NOT_UPDATE' ) {
                            return 1;
                        }

                        my $roles = join( ' ', map { $_->name } $me->roles );

                        if ( $roles =~ /\buser\b/ ) {

                            my $exists = $self->search(
                                {
                                    city_id      => $city->id,
                                    institute_id => $institute_id,
                                }
                            )->next;

                            return 0 if $exists && $exists->id != $me->id;

                        }

                        return 1;
                      }
                },
                network_ids => {
                    required   => 1,
                    type       => 'Str',
                    post_check => sub {
                        my $r = shift;

                        my $str = $r->get_value('network_ids');
                        return 1 if $str =~ /^DO_NOT_UPDATE$/;
                        return 1 if $str =~ /^0$/;

                        return 0 unless $str =~ /^([0-9]+,)*[0-9]+$/;

                        # eu preciso existir!
                        my $me = $self->find( $r->get_value('id') );
                        return 0 unless $me;

                        my $roles = join( ' ', map { $_->name } $me->roles );

                        my $city_id = $r->get_value('city_id') || $me->city_id;

                        my @nets       = split /,/, $str;
                        my $invalid    = 0;
                        my $institutes = {};

                        foreach my $netid (@nets) {

                            # rede precisa existir
                            my $net = $self->result_source->schema->resultset('Network')->find( { id => $netid } );
                            $invalid++ and last unless $net;

                            if ( $roles =~ /\buser\b/ ) {

                                $institutes->{ $net->institute_id } = 1;

                                # pra ser usuario, precisa ser de alguma cidade
                                my $city = $self->result_source->schema->resultset('City')->find($city_id);
                                $invalid++ and last unless $city;

                                my $exists = $self->search(
                                    {
                                        city_id      => $city_id,
                                        institute_id => $net->institute_id,
                                    }
                                )->next;

                                $invalid++ and last if ( $exists && $exists->id != $me->id );
                            }
                        }

                        # nao pode ficar em duas redes de institutos diferentes
                        return 0 if keys %$institutes != 1;

                        return 0 if $invalid;
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

                can_create_indicators => { required => 0, type => 'Bool' },
                regions_enabled       => { required => 0, type => 'Bool' },
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
                    required => 1,
                    type     => EmailAddress
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
            delete $values{cur_lang} unless $values{cur_lang};

            do { delete $values{$_} unless defined $values{$_} }
              for qw/can_create_indicators regions_enabled/;

            my $role = delete $values{role};

            my $network_id = delete $values{network_id};

            if ($network_id) {
                my $net = $self->result_source->schema->resultset('Network')->find( { id => $network_id } );
                my $inst = $net->institute;
                $values{institute_id} = $net->institute_id;

                $values{regions_enabled}       = $inst->can_use_regions       if !exists $values{regions_enabled};
                $values{can_create_indicators} = $inst->can_create_indicators if !exists $values{can_create_indicators};
            }

            my $user = $self->create( \%values, active => 1 );

            $user->add_to_user_roles( { role => { name => $role } } );
            $user->add_to_network_users( { network_id => $network_id } );

            $user->discard_changes;
            return $user;
        },
        update => sub {
            my %values = shift->valid_values;
            delete $values{password_confirm};
            delete $values{password} unless $values{password};
            delete $values{city_id}  unless $values{city_id};
            delete $values{cur_lang} unless $values{cur_lang};

            delete $values{active} unless $values{active};

            do { delete $values{$_} unless defined $values{$_} }
              for keys %values;
            return unless keys %values;

            my $network_ids = delete $values{network_ids};
            my $user        = $self->find( delete $values{id} );

            if ( $network_ids ne 'DO_NOT_UPDATE' ) {
                my @network_ids = split /,/, $network_ids;
                $user->network_users->delete;

                my $institute_id;
                for ( grep { $_ > 0 } @network_ids ) {
                    $user->add_to_network_users( { network_id => $_ } );

                    if ( !$institute_id ) {
                        my $net = $self->result_source->schema->resultset('Network')->find( { id => $_ } );
                        $institute_id = $net->institute_id;
                    }
                }

                $values{institute_id} = $institute_id;
            }

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
            return 1 if !$user;
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
