package Iota::Schema::ResultSet::UserIndicator;

use namespace::autoclean;

use Moose;
extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use JSON qw /encode_json/;
use String::Random;
use MooseX::Types::Email qw/EmailAddress/;

use Iota::Types qw /VariableType DataStr/;

sub _build_verifier_scope_name { 'user.indicator' }
use Iota::IndicatorFormula;
use DateTimeX::Easy;

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                justification_of_missing_field => {
                    required => 0,
                    type     => 'Str'
                },
                goal => {
                    required => 0,
                    type     => 'Str'
                },
                user_id => {
                    required => 1,
                    type     => 'Int',
                },

                region_id => {
                    required => 0,
                    type     => 'Int',
                },

                indicator_id => {
                    required   => 1,
                    type       => 'Int',
                    post_check => sub {
                        my $r = shift;
                        return $self->result_source->schema->resultset('Indicator')
                          ->find( { id => $r->get_value('indicator_id') } ) ? 1 : 0;
                    }
                },
                valid_from => {
                    required   => 1,
                    type       => DataStr,
                    post_check => sub {
                        my $r = shift;

                        my $ind =
                          $self->result_source->schema->resultset('Indicator')
                          ->find( { id => $r->get_value('indicator_id') } );
                        my $schema = $self->result_source->schema;

                        my $f = new Iota::IndicatorFormula(
                            formula => $ind->formula,
                            schema  => $schema
                        );
                        my ($any_var) = $f->variables;

                        my $var = $schema->resultset('Variable')->find( { id => $any_var } );
                        my $date = DateTimeX::Easy->new( $r->get_value('valid_from') )->datetime;

                        my $valid_from =
                          eval { $schema->f_extract_period_edge( ( $var ? $var->period : 'yearly' ), $date ) }
                          ->{period_begin};

                        return $self->search(
                            {
                                indicator_id => $r->get_value('indicator_id'),
                                user_id      => $r->get_value('user_id'),
                                valid_from   => $valid_from
                            }
                        )->count == 0;

                    }
                },
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
                justification_of_missing_field => {
                    required => 0,
                    type     => 'Str'
                },
                goal => {
                    required => 0,
                    type     => 'Str',
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

            my $ind = $self->result_source->schema->resultset('Indicator')->find( { id => $values{indicator_id} } );
            my $schema = $self->result_source->schema;

            my $f = new Iota::IndicatorFormula(
                formula => $ind->formula,
                schema  => $schema
            );
            my ($any_var) = $f->variables;

            my $var = $schema->resultset('Variable')->find( { id => $any_var } );
            my $date = DateTimeX::Easy->new( $values{valid_from} )->datetime;

            $values{valid_from} =
              $schema->f_extract_period_edge( $var ? $var->period : 'yearly', $date )->{period_begin};
            my $varvalue = $self->create( \%values );
            return $varvalue;
        },
        update => sub {
            my %values = shift->valid_values;

            $values{justification_of_missing_field} ||= '';

            my $var = $self->find( delete $values{id} )->update( \%values );
            $var->discard_changes;
            return $var;
        }
    };
}

1;

