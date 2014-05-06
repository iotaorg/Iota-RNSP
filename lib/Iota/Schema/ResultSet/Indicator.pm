
package Iota::Schema::ResultSet::Indicator;

use namespace::autoclean;

use Moose;
extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Iota::IndicatorData;
use Text2URI;
my $text2uri = Text2URI->new();    # tem lazy la, don't worry

use Data::Verifier;
use Iota::IndicatorFormula;

use Iota::Types qw /VisibilityLevel/;

sub _build_verifier_scope_name { 'indicator' }

sub visibility_level_post_check {
    my $self = shift;
    my $r   = shift;

    my $lvl = $r->get_value('visibility_level');
    return 1 if $lvl eq 'public';

    return &is_user($self, $r->get_value('visibility_user_id')) if $lvl eq 'private';
    return &is_user($self, $r->get_value('visibility_users_id')) if $lvl eq 'restrict';

    return 1 if $lvl eq 'network'  && ( $r->get_value('visibility_networks_id')   || '' ) =~ /^(?:(?:\d*,?)\d+)+$/;

    return 0;
}

sub is_user {
    my ($self, $input) = @_;

    return  0 if ( $input  || '' ) !~ /^(?:(?:\d*,?)\d+)+$/;

    my @ids = split /,/, $input;

    return 1 unless @ids;

    my $ct = $self->result_source->schema->resultset('User')->search( {
        id => {'in' => \@ids},
        active => 1,
        city_id => {'!=' => undef}
    } )->count;

    return $ct == scalar @ids;
}

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                name    => { required => 1, type => 'Str' },
                formula => {
                    required   => 1,
                    type       => 'Str',
                    post_check => sub {
                        my $r = shift;
                        my $f = eval {
                            Iota::IndicatorFormula->new(
                                formula => $r->get_value('formula'),
                                schema  => $self->result_source->schema
                            );
                        };
                        return $@ eq '';
                    },
                },
                goal    => { required => 0, type => 'Num' },
                axis_id => {
                    required   => 1,
                    type       => 'Int',
                    post_check => sub {
                        my $r = shift;
                        my $axis =
                          $self->result_source->schema->resultset('Axis')->find( { id => $r->get_value('axis_id') } );
                        return defined $axis;
                      }
                },
                user_id      => { required => 1, type => 'Int' },
                source       => { required => 0, type => 'Str' },
                explanation  => { required => 0, type => 'Str' },
                observations => { required => 0, type => 'Str' },

                goal_source   => { required => 0, type => 'Str' },
                tags          => { required => 0, type => 'Str' },
                goal_operator => { required => 0, type => 'Str' },
                chart_name    => { required => 0, type => 'Str' },

                goal_explanation => { required => 0, type => 'Str' },
                sort_direction   => { required => 0, type => 'Str' },

                variety_name => { required => 0, type => 'Str' },

                featured_in_home => { required => 0, type => 'Bool' },

                indicator_type => { required => 0, type => 'Str' },

                all_variations_variables_are_required => { required => 0, type => 'Bool' },
                summarization_method                  => { required => 0, type => 'Str' },

                dynamic_variations => { required => 0, type => 'Bool' },

                visibility_level => {
                    required   => 1,
                    type       => VisibilityLevel,
                    post_check => sub{&visibility_level_post_check($self, shift)}
                },
                visibility_user_id    => { required => 0, type => 'Int' },
                visibility_country_id => { required => 0, type => 'Int' },
                visibility_users_id   => { required => 0, type => 'Str' },
                visibility_networks_id   => { required => 0, type => 'Str' },

            },
        ),

        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                id      => { required => 1, type => 'Int' },
                name    => { required => 0, type => 'Str' },
                formula => {
                    required   => 0,
                    type       => 'Str',
                    post_check => sub {
                        my $r = shift;
                        my $f = eval {
                            new Iota::IndicatorFormula(
                                formula => $r->get_value('formula'),
                                schema  => $self->result_source->schema
                            );
                        };
                        return $@ eq '';
                    },
                },
                goal    => { required => 0, type => 'Num' },
                axis_id => {
                    required   => 0,
                    type       => 'Int',
                    post_check => sub {
                        my $r = shift;
                        my $axis =
                          $self->result_source->schema->resultset('Axis')->find( { id => $r->get_value('axis_id') } );
                        return defined $axis;
                      }
                },
                source       => { required => 0, type => 'Str' },
                explanation  => { required => 0, type => 'Str' },
                observations => { required => 0, type => 'Str' },

                goal_source   => { required => 0, type => 'Str' },
                tags          => { required => 0, type => 'Str' },
                goal_operator => { required => 0, type => 'Str' },

                goal_explanation => { required => 0, type => 'Str' },
                sort_direction   => { required => 0, type => 'Str' },
                chart_name       => { required => 0, type => 'Str' },

                variety_name   => { required => 0, type => 'Str' },
                indicator_type => { required => 0, type => 'Str' },

                all_variations_variables_are_required => { required => 0, type => 'Bool' },
                summarization_method                  => { required => 0, type => 'Str' },

                featured_in_home   => { required => 0, type => 'Bool' },
                dynamic_variations => { required => 0, type => 'Bool' },

                visibility_level => {
                    required   => 0,
                    type       => VisibilityLevel,
                    post_check => sub{&visibility_level_post_check($self, shift)}
                },
                visibility_user_id    => { required => 0, type => 'Int' },
                visibility_country_id => { required => 0, type => 'Int' },
                visibility_users_id   => { required => 0, type => 'Str' },
                visibility_networks_id   => { required => 0, type => 'Str' },

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
            $values{name_url} = $text2uri->translate( $values{name} );

            my $visibility_users_id = delete $values{visibility_users_id};
            my @visible_users = $visibility_users_id ? split /,/, $visibility_users_id : ();

            my $visibility_networks_id = delete $values{visibility_networks_id};
            my @visible_networks = $visibility_networks_id ? split /,/, $visibility_networks_id : ();

            my $formula = Iota::IndicatorFormula->new(
                formula => $values{formula},
                schema  => $self->result_source->schema
            );
            if ( $formula->_variable_count == 0 ) {
                $values{period}        = 'yearly';
                $values{variable_type} = 'int';
            }

            $values{formula_human} = $formula->as_human;
            my $var = $self->create( \%values );

            $var->add_to_indicator_variables( { variable_id => $_ } ) for $formula->variables;

            if ( $values{visibility_level} eq 'restrict' ) {
                $var->add_to_indicator_user_visibilities(
                    {
                        user_id    => $_,
                        created_by => $var->user_id
                    }
                ) for @visible_users;
            }elsif ( $values{visibility_level} eq 'network' ) {
                $var->add_to_indicator_network_visibilities(
                    {
                        network_id    => $_,
                        created_by => $var->user_id
                    }
                ) for @visible_networks;
            }

            if ( $formula->_variable_count ) {
                my $anyvar = $var->indicator_variables->next->variable;
                $var->update(
                    {
                        period        => $anyvar->period,
                        variable_type => $anyvar->type,
                    }
                ) if ( !$var->period || $var->period ne $anyvar->period );
            }

            my $data = Iota::IndicatorData->new( schema => $self->result_source->schema );

            $data->upsert( indicators => [ $var->id ], );

            return $var;
        },
        update => sub {
            my %values = shift->valid_values;

            $values{name_url} = $text2uri->translate( $values{name} ) if exists $values{name} && $values{name};
            do { delete $values{$_} unless defined $values{$_} }
              for keys %values;
            return unless keys %values;

            do { $values{$_} = undef unless exists $values{$_} }
              for qw/
              goal goal_source goal_explanation goal_operator
              tags source observations
              /;



            my $visibility_users_id = delete $values{visibility_users_id};
            my @visible_users = $visibility_users_id ? split /,/, $visibility_users_id : ();

            my $visibility_networks_id = delete $values{visibility_networks_id};
            my @visible_networks = $visibility_networks_id ? split /,/, $visibility_networks_id : ();

            my $var             = $self->find( delete $values{id} );
            my $formula_changed = 0;
            if ( exists $values{formula} && $values{formula} && $values{formula} ne $var->formula ) {
                $formula_changed++;

                my $formula = Iota::IndicatorFormula->new(
                    formula => $values{formula},
                    schema  => $self->result_source->schema
                );
                $values{formula_human} = $formula->as_human;

                $var->indicator_variables->delete;
                $var->add_to_indicator_variables( { variable_id => $_ } ) for $formula->variables;

                if ( $formula->_variable_count ) {
                    my $anyvar = $var->indicator_variables->next->variable;
                    $values{period}        = $anyvar->period;
                    $values{variable_type} = $anyvar->type;
                }
            }

            $values{visibility_user_id} = undef
                if exists $values{visibility_level} && $values{visibility_level} eq 'public';

            $var->update( \%values );
            if ( exists $values{visibility_level} ) {


                $var->indicator_user_visibilities->delete;
                $var->indicator_network_visibilities->delete;

                if ( $values{visibility_level} eq 'restrict' ) {

                    $var->indicator_user_visibilities->delete;

                    $var->add_to_indicator_user_visibilities(
                        {
                            user_id    => $_,
                            created_by => $var->user_id
                        }
                    ) for @visible_users;

                }elsif ( $values{visibility_level} eq 'network' ) {

                    $var->indicator_user_visibilities->delete;

                    $var->add_to_indicator_network_visibilities(
                        {
                            network_id    => $_,
                            created_by => $var->user_id
                        }
                    ) for @visible_networks;

                }else{



                }
            }
            $var->discard_changes;

            if ($formula_changed) {
                my $data = Iota::IndicatorData->new( schema => $self->result_source->schema );

                $data->upsert( indicators => [ $var->id ], );

                # recalcula a regiao 3
                my @ids = map {$_->{id}} $self->result_source->schema->resultset('Region')->search({
                    depth_level => 3
                }, {
                    columns => ['id'],
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator'
                })->all;

                $data->upsert( indicators => [ $var->id ], regions_id => \@ids);

                # recalcula a regiao 2 que pode nao ter filha, logo nao recalculou a de cima.
                @ids = map {$_->{id}} $self->result_source->schema->resultset('Region')->search({
                    depth_level => 2
                }, {
                    columns => ['id'],
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator'
                })->all;

                $data->upsert( indicators => [ $var->id ], regions_id => \@ids);

            }

            return $var;
        },

    };
}

sub filter_visibilities {
    my ($self, %filters) = @_;

    my @users_ids = exists $filters{users_ids} && $filters{users_ids} ? grep {/^[0-9]+$/} @{$filters{users_ids}} : ();
    my @networks_ids = exists $filters{networks_ids} && $filters{networks_ids} ? grep {/^[0-9]+$/} @{$filters{networks_ids}} : ();

    @users_ids = ($filters{user_id}) if exists $filters{user_id} && $filters{user_id} && $filters{user_id} =~ /^[0-9]+$/;

    return $self->search({
        'me.id' => {
            'in' => $self->result_source->schema->resultset('Indicator')->search(
                {
                    '-or' => [
                        { visibility_level => 'public' },

                        (@users_ids
                        ? (
                            { visibility_level => 'private', visibility_user_id => { 'in' => \@users_ids } },
                            { visibility_level => 'restrict', 'indicator_user_visibilities.user_id' => { 'in' => \@users_ids } },
                        ) : ()),
                        (@networks_ids
                        ? (
                            { visibility_level => 'network', 'indicator_network_visibilities.network_id' => { 'in' => \@networks_ids } },
                        ) : ()),
                    ]
                },
                {
                    join     => ['indicator_user_visibilities', 'indicator_network_visibilities'],
                }
            )->get_column('id')->as_query
        }
    });

}

1;

