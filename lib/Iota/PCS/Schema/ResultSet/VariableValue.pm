
package Iota::PCS::Schema::ResultSet::VariableValue;

use namespace::autoclean;

use Moose;
extends 'DBIx::Class::ResultSet';
with 'Iota::PCS::Role::Verification';
with 'Iota::PCS::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use JSON qw /encode_json/;
use String::Random;
use MooseX::Types::Email qw/EmailAddress/;

use Iota::PCS::Types qw /VariableType DataStr/;

sub _build_verifier_scope_name { 'variable.value' }
use DateTimeX::Easy;

# TODO verificar se isso nao vai ferrar com alguma
# variavel do tipo string
my $str2number = sub {
    my $str = shift;
    if ($str) {
        $str =~ s/\.(\d{3})/$1/g;
        $str =~ s/\s(\d{3})/$1/g;
        $str =~ s/\,/./;
    }
    return $str;
};

sub value_check {
    my ( $self, $r ) = @_;

    my $variable_id = $r->get_value('variable_id');
    my $schema      = $self->result_source->schema;
    unless ($variable_id) {
        $variable_id = $self->search( { id => $r->get_value('id') } )->first->variable_id;
    }

    my $var = $schema->resultset('Variable')->find( { id => $variable_id } );

    if ( $var->type eq 'int' && $r->get_value('value') !~ /^[-+]?[0-9]+$/ ) {
        return 0;
    }
    elsif ( $var->type eq 'num' && $r->get_value('value') !~ /^[-+]?[0-9]+\.?[0-9]*$/ ) {
        return 0;
    }

    return 1;
}

# TODO deixar o campo 'source' obrigatorio quando o campo 'value' for vazio
sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            profile => {

                value => {
                    required   => 0,
                    type       => 'Str',
                    post_check => sub {
                        my $r = shift;
                        return $self->value_check($r);
                    },
                    filters => [$str2number]
                },
                source        => { required => 0, type => 'Str' },
                observations  => { required => 0, type => 'Str' },
                user_id       => { required => 1, type => 'Int' },
                value_of_date => {
                    required   => 1,
                    type       => DataStr,
                    post_check => sub {
                        my $r = shift;

                        #return 0 if (!$r->get_value('value'));  # TODO verificar se foi salvo justificativa

                        my $schema = $self->result_source->schema;
                        my $var    = $schema->resultset('Variable')->find( { id => $r->get_value('variable_id') } );
                        my $date   = DateTimeX::Easy->new( $r->get_value('value_of_date') )->datetime;

                        # f_extract_period_edge
                        return $var && $self->search(
                            {
                                user_id     => $r->get_value('user_id'),
                                variable_id => $r->get_value('variable_id'),
                                valid_from  => $schema->f_extract_period_edge( $var->period, $date )->{period_begin}
                            }
                        )->count == 0;
                      }

                },
                variable_id => {
                    required   => 1,
                    type       => 'Int',
                    post_check => sub {
                        my $r = shift;
                        return $self->result_source->schema->resultset('Variable')
                          ->find( { id => $r->get_value('variable_id') } ) ? 1 : 0;
                      }
                },
            },
        ),

        update => Data::Verifier->new(
            profile => {

                source => { required => 0, type => 'Str' },
                id     => {
                    required   => 1,
                    type       => 'Int',
                    post_check => sub {
                        my $r = shift;
                        return $self->search( { id => $r->get_value('id') } )->count == 1;
                      }

                },
                observations => { required => 0, type => 'Str' },
                value        => {
                    required   => 0,
                    type       => 'Str',
                    post_check => sub {
                        my $r = shift;
                        return $self->value_check($r);
                    },
                    filters => [$str2number]
                },
                value_of_date => {
                    required   => 1,
                    type       => DataStr,
                    post_check => sub {
                        my $r = shift;

                        #return 0 if (!$r->get_value('value')); # TODO verificar se foi salvo justificativa

                        my $schema = $self->result_source->schema;
                        my $var = $self->search( { id => $r->get_value('id') } )->first;

                        my $date = DateTimeX::Easy->new( $r->get_value('value_of_date') )->datetime;

                        # f_extract_period_edge
                        return $var && $self->search(
                            {
                                id => $r->get_value('id'),
                                valid_from =>
                                  $schema->f_extract_period_edge( $var->variable->period, $date )->{period_begin}
                            }
                        )->count == 1;
                      }

                },
            },
        ),

        put => Data::Verifier->new(
            profile => {

                source => { required => 0, type => 'Str' },
                file_id => { required => 0, type => 'Int' },

                value => {
                    required   => 0,
                    type       => 'Str',
                    post_check => sub {
                        my $r = shift;

                        return $self->value_check($r);
                    },
                    filters => [$str2number]
                },
                observations  => { required => 0, type => 'Str' },
                user_id       => { required => 1, type => 'Int' },
                value_of_date => {
                    required => 1,
                    type     => DataStr,

                    #post_check => sub {
                    #    my $r = shift;
                    #    return 0 if (!$r->get_value('justification_of_missing_field') && !$r->get_value('value'));
                    #    return 1;
                    #},

                },
                variable_id => {
                    required   => 1,
                    type       => 'Int',
                    post_check => sub {
                        my $r = shift;
                        return $self->result_source->schema->resultset('Variable')
                          ->find( { id => $r->get_value('variable_id') } ) ? 1 : 0;
                      }
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
            $values{value_of_date} = DateTimeX::Easy->new( $values{value_of_date} )->datetime;

            my $schema = $self->result_source->schema;
            my $var    = $schema->resultset('Variable')->find( { id => $values{variable_id} } );
            my $date   = $values{value_of_date};

            my $dates = $schema->f_extract_period_edge( $var->period, $date );
            $values{valid_from}  = $dates->{period_begin};
            $values{valid_until} = $dates->{period_end};

            my $varvalue = $self->create( \%values );

            $varvalue->discard_changes;
            return $varvalue;
        },
        update => sub {
            my %values = shift->valid_values;
            $values{value_of_date} = DateTimeX::Easy->new( $values{value_of_date} )->datetime;

            do { delete $values{$_} unless defined $values{$_} }
              for keys %values;
            return unless keys %values;

            $values{observations} ||= undef;
            $values{source} ||= undef;

            my $var = $self->find( delete $values{id} )->update( \%values );
            $var->discard_changes;
            return $var;
        },
        put => sub {
            my %values = shift->valid_values;

            my $schema = $self->result_source->schema;
            my $var = $schema->resultset('Variable')->find( $values{variable_id} );

            $self->_put($var->period, %values);
        },

    };
}

sub _put {
    my ($self, $period, %values) = @_;
    $values{value_of_date} = DateTimeX::Easy->new( $values{value_of_date} )->datetime;

    my $schema = $self->result_source->schema;

    do { delete $values{$_} unless defined $values{$_} }
        for keys %values;
    return unless keys %values;

    my $dates = $schema->f_extract_period_edge( $period, $values{value_of_date} );

    # procura por uma variavel daquele usuario naquele periodo, se
    # existir, atualiza a data e o valor!
    my $row = $self->search(
        {
            user_id     => $values{user_id},
            variable_id => $values{variable_id},
            valid_from  => $dates->{period_begin}
        }
    )->next;

    if ($row) {
        $row->update(
            {
                value         => $values{value},
                value_of_date => $values{value_of_date},

                ( exists $values{source} ? ( source => $values{source} ) : () ),

                ( exists $values{observations} ? ( observations => $values{observations} ) : () ),

                ( exists $values{file_id} ? ( file_id => $values{file_id} ) : () ),

            }
        );
        $row->discard_changes;
    }
    else {

        $values{valid_from}  = $dates->{period_begin};
        $values{valid_until} = $dates->{period_end};

        $row = $self->create( \%values );
    }
    return $row;
}

1;

