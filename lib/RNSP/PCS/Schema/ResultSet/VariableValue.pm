
package RNSP::PCS::Schema::ResultSet::VariableValue;

use namespace::autoclean;

use Moose;
extends 'DBIx::Class::ResultSet';
with 'RNSP::PCS::Role::Verification';
with 'RNSP::PCS::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use JSON qw /encode_json/;
use String::Random;
use MooseX::Types::Email qw/EmailAddress/;

use RNSP::PCS::Types qw /VariableType/;

sub _build_verifier_scope_name {'variable.value'}

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            profile => {
                value       => { required => 0, type => 'Str' },
                user_id     => { required => 1, type => 'Int' },
                variable_id => { required => 1, type => 'Int',
                                 post_check => sub {
                                    my $r = shift;

                                    return $self->result_source->schema->resultset('Variable')->find({
                                        id => $r->get_value('variable_id')
                                    });
                                 }
                },
            },
        ),

        update => Data::Verifier->new(
            profile => {
                id          => { required => 1, type => 'Int' },
                value       => { required => 0, type => 'Str' },
            },
        ),



    };
}


sub action_specs {
    my $self = shift;
    return {
        create => sub {
            my %values = shift->valid_values;

            my $var = $self->create( \%values );

            $var->discard_changes;
            return $var;
        },
        update => sub {
            my %values = shift->valid_values;

            do { delete $values{$_} unless defined $values{$_}} for keys %values;
            return unless keys %values;

            my $var = $self->find( delete $values{id} )->update( \%values );
            $var->discard_changes;
            return $var;
        },

    };
}

1;

