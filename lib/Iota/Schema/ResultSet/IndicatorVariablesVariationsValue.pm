package Iota::Schema::ResultSet::IndicatorVariablesVariationsValue;

use namespace::autoclean;

use Moose;
extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use Iota::IndicatorFormula;
use Iota::IndicatorData;
use Iota::Types qw /VariableType DataStr/;

sub _build_verifier_scope_name { 'indicator.variation_value' }

sub value_check {
    my ( $self, $r ) = @_;

    my $indicator_variables_variation_id = $r->get_value('indicator_variables_variation_id');
    my $schema                           = $self->result_source->schema;
    unless ($indicator_variables_variation_id) {
        $indicator_variables_variation_id =
          $self->search( { id => $r->get_value('id') } )->first->indicator_variables_variation_id;
    }

    my $var = $schema->resultset('IndicatorVariablesVariation')->find( { id => $indicator_variables_variation_id } );

    if ( $var->type eq 'int' && $r->get_value('value') !~ /^[-+]?[0-9]+$/ ) {
        return 0;
    }
    elsif ( $var->type eq 'num' && $r->get_value('value') !~ /^[-+]?[0-9]+\.?[0-9]*$/ ) {
        return 0;
    }

    return 1;
}

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                value_of_date          => { required => 1, type => DataStr },
                user_id                => { required => 1, type => 'Int' },
                region_id              => { required => 0, type => 'Int' },
                indicator_variation_id => {
                    required   => 1,
                    type       => 'Int',
                    post_check => sub {
                        my $r = shift;
                        return $self->result_source->schema->resultset('IndicatorVariation')
                          ->find( { id => $r->get_value('indicator_variation_id') } ) ? 1 : 0;
                    }
                },
                indicator_variables_variation_id => { required => 1, type => 'Int' },
                period                           => { required => 0, type => 'Str' },
                value                            => {
                    required   => 0,
                    type       => 'Str',
                    post_check => sub {
                        my $r = shift;
                        return $self->value_check($r);
                    },
                },
                summarization_method => { required => 0, type => 'Str' },
            },
        ),

        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                id    => { required => 1, type => 'Int' },
                value => {
                    required   => 0,
                    type       => 'Str',
                    post_check => sub {
                        my $r = shift;
                        return $self->value_check($r);
                    },
                },
                summarization_method => { required => 0, type => 'Str' },
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
            my $schema = $self->result_source->schema;

            if ( my $period = delete $values{period} ) {
                my $dates = $schema->f_extract_period_edge( $period, $values{value_of_date} );

                if ( exists $values{region_id} ) {
                    my $region        = $schema->resultset('Region')->find( $values{region_id} );
                    my $value_of_date = DateTimeX::Easy->new( $values{value_of_date} );
                    if ( $region->depth_level <= 2 ) {
                        if ( $region->subregions_valid_after
                            && DateTime->compare( $value_of_date, $region->subregions_valid_after ) >= 0 ) {

                            $values{active_value} = 0;
                        }
                        else {
                            # se nao tem subregions, sempre eh o ativo!
                            $values{active_value} = 1;
                        }
                    }
                    elsif ( $region->depth_level == 3 ) {
                        my $upper = $region->upper_region;

                        die "upper region valid date cannot be null\n" unless ( $upper->subregions_valid_after );

                        die "cannot save subregion value before upper region tell subregions is valid\n"
                          if ( DateTime->compare( $value_of_date, $upper->subregions_valid_after ) < 0 );

                    }
                }

                $values{valid_from}  = $dates->{period_begin};
                $values{valid_until} = $dates->{period_end};
            }
            else {
                # pra deixar criar um dia um indicador sem variavel,
                # só com variaveis de variacoes
                $values{valid_from} = substr( $values{value_of_date}, 0, 10 );
                $values{valid_until} = $values{valid_from};
            }

            my $var;
            if ( exists $values{active_value} && $values{active_value} == 0 ) {
                eval {
                    $schema->txn_do(
                        sub {
                            $var = $self->create( \%values );
                        }
                    );
                };

                # se ja existe, e nao eh ativo, entao ja entra ~morto~.
                if ( $@ && $@ =~ /duplicate key value violates unique constraint/ ) {
                    $var = $self->create( { %values, end_ts => \'now()' } );
                }
                elsif ($@) {
                    die $@;
                }
            }
            else {
                $var = $self->create( \%values );
            }

            $var->discard_changes;

            my $data = Iota::IndicatorData->new( schema => $self->result_source->schema );

            $data->upsert(
                indicators => [
                    $data->indicators_from_variation_variables(
                        variables => [ $var->indicator_variables_variation_id ]
                    )
                ],
                dates   => [ $var->valid_from->datetime ],
                user_id => $var->user_id,

                variables_variation_ids => [ $var->indicator_variables_variation_id ],

                ( regions_id => [ $values{region_id} ] ) x !!exists $values{region_id},

            );

            return $var;
        },
        update => sub {
            my %values = shift->valid_values;

            do { delete $values{$_} unless defined $values{$_} }
              for keys %values;
            return unless keys %values;

            my $var = $self->find( delete $values{id} )->update( \%values );
            $var->discard_changes;

            my $data = Iota::IndicatorData->new( schema => $self->result_source->schema );

            $data->upsert(
                indicators => [
                    $data->indicators_from_variation_variables(
                        variables => [ $var->indicator_variables_variation_id ]
                    )
                ],
                dates   => [ $var->valid_from->datetime ],
                user_id => $var->user_id,

                variables_variation_ids => [ $var->indicator_variables_variation_id ],

                ( regions_id => [ $var->region_id ] ) x !!$var->region_id,
            );

            return $var;
        },

    };
}

1;

