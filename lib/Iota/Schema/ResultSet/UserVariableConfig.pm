package Iota::Schema::ResultSet::UserVariableConfig;

use namespace::autoclean;

use Moose;
extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Data::Verifier;

sub _build_verifier_scope_name { 'user.variable_config' }

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                display_in_home => {
                    required => 1,
                    type     => 'Bool'
                },
                user_id => {
                    required => 1,
                    type     => 'Int',
                },
                position => {
                    required => 0,
                    type     => 'Int',
                },

                variable_id => {
                    required   => 1,
                    type       => 'Int',
                    post_check => sub {
                        my $r = shift;
                        my $exists =
                          $self->result_source->schema->resultset('Variable')
                          ->find( { id => $r->get_value('variable_id') } );
                        return 0 unless $exists;

                        return $self->search(
                            {
                                variable_id => $r->get_value('variable_id'),
                                user_id      => $r->get_value('user_id'),
                            }
                        )->count ? 0 : 1;
                      }
                }
            }
        ),

        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                id => {
                    required   => 1,
                    type       => 'Int',
                    post_check => sub {
                        my $r = shift;
                        return $self->find( { id => $r->get_value('id') } ) ? 1 : 0;
                      }
                },
                position => {
                    required => 0,
                    type     => 'Int',
                },
                display_in_home => {
                    required => 1,
                    type     => 'Bool'
                }
            }
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

            my $obj = $self->create( \%values );
            return $obj;
        },
        update => sub {
            my %values = shift->valid_values;
            do { delete $values{$_} unless defined $values{$_} }
              for keys %values;
            return unless keys %values;

            my $obj = $self->find( delete $values{id} )->update( \%values );
            $obj->discard_changes;
            return $obj;
          }
    };
}

1;

