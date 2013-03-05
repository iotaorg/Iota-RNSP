package Iota::PCS::Schema::ResultSet::IndicatorVariablesVariationsValue;

use namespace::autoclean;

use Moose;
extends 'DBIx::Class::ResultSet';
with 'Iota::PCS::Role::Verification';
with 'Iota::PCS::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use Iota::IndicatorFormula;
use Iota::PCS::Types qw /VariableType DataStr/;

sub _build_verifier_scope_name { 'indicator.variation_value' }

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            profile => {
                value_of_date          => { required => 1, type => DataStr },
                user_id                => { required => 1, type => 'Int' },
                indicator_variation_id => {
                  required => 1,
                  type => 'Int',
                  post_check => sub {
                     my $r = shift;
                     return $self->result_source->schema->resultset('IndicatorVariation')
                        ->find( { id => $r->get_value('indicator_variation_id') } ) ? 1 : 0;
                  }
               },
                indicator_variables_variation_id => { required => 1, type => 'Int' },
                period                 => { required => 0, type => 'Str' },
                value                  => { required => 0, type => 'Str' },
            },
        ),

        update => Data::Verifier->new(
            profile => {
                id      => { required => 1, type => 'Int' },
                value   => { required => 0, type => 'Str' },
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

            if (my $period = delete $values{period}){
               my $dates = $schema->f_extract_period_edge($period , $values{value_of_date} );

               $values{valid_from}  = $dates->{period_begin};
               $values{valid_until} = $dates->{period_end};
            }else{
               # pra deixar criar um dia um indicador sem variavel,
               # só com variaveis de variacoes
               $values{valid_from}  = substr($values{value_of_date},0,10);
               $values{valid_until} = $values{valid_from};
            }

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

