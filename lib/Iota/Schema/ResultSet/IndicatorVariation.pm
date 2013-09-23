
package Iota::Schema::ResultSet::IndicatorVariation;

use namespace::autoclean;

use Moose;
extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use Iota::IndicatorFormula;

sub _build_verifier_scope_name { 'indicator.variation' }

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                name => {
                    required   => 1,
                    type       => 'Str',
                    post_check => sub {
                        my $r = shift;

                        my $schema = $self->result_source->schema;

                        my $indicator = $schema->resultset('Indicator')
                          ->search( { id => $r->get_value('indicator_id') }, { columns => ['user_id'] } )->next;

                        return $self->search(
                            {
                                indicator_id => $r->get_value('indicator_id'),
                                user_id      => [ $indicator->user_id, $r->get_value('user_id') ],
                                name         => $r->get_value('name'),
                            }
                        )->count == 0;
                      }
                },
                indicator_id => { required => 1, type => 'Int' },
                order        => { required => 1, type => 'Int' },
                user_id      => { required => 1, type => 'Int' },
            },
        ),

        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                id   => { required => 1, type => 'Int' },
                name => {
                    required   => 1,
                    type       => 'Str',
                    post_check => sub {
                        my $r = shift;

                        my $schema = $self->result_source->schema;
                        my $me     = $self->find( $r->get_value('id') );

                        return 1 if $me->name eq $r->get_value('name');

                        my $indicator = $schema->resultset('Indicator')
                          ->search( { id => $me->indicator_id }, { columns => ['user_id'] } )->next;

                        return $self->search(
                            {
                                indicator_id => $me->indicator_id,
                                user_id      => [ $indicator->user_id, $me->user_id ],
                                name         => $r->get_value('name'),
                            }
                        )->count == 0;
                      }
                },
                order => { required => 0, type => 'Int' },
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

