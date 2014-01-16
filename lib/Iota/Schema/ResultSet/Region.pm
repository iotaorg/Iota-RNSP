
package Iota::Schema::ResultSet::Region;

use namespace::autoclean;

use Moose;
extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Text2URI;
my $text2uri = Text2URI->new();    # tem lazy la, don't worry

use Data::Verifier;
use Iota::IndicatorFormula;
use Iota::Types qw /DataStr/;

sub _build_verifier_scope_name { 'city.region' }

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                name        => { required => 1, type => 'Str' },
                description => { required => 0, type => 'Str' },
                city_id     => { required => 1, type => 'Int' },
                created_by  => { required => 1, type => 'Int' },

                polygon_path => { required => 0, type => 'Str' },

                upper_region => {
                    required   => 0,
                    type       => 'Int',
                    post_check => sub {
                        my $r = shift;
                        my $axis =
                          $self->result_source->schema->resultset('Region')
                          ->find( { id => $r->get_value('upper_region') } );
                        return defined $axis;
                      }
                },

                automatic_fill => { required => 0, type => 'Bool' },

            },
        ),

        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                id           => { required => 1, type => 'Int' },
                name         => { required => 0, type => 'Str' },
                description  => { required => 0, type => 'Str' },
                polygon_path => { required => 0, type => 'Str' },

                upper_region => {
                    required   => 0,
                    type       => 'Int',
                    post_check => sub {
                        my $r = shift;
                        my $axis =
                          $self->result_source->schema->resultset('Region')
                          ->find( { id => $r->get_value('upper_region') } );
                        return defined $axis && $r->get_value('upper_region') != $r->get_value('id');
                      }
                },
                subregions_valid_after => { required => 0, type => DataStr },

                automatic_fill => { required => 0, type => 'Bool' },

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

            $values{name_url} = $text2uri->translate( $values{name} );

            $values{depth_level} = 3 if exists $values{upper_region} && $values{upper_region};

            if ( exists $values{depth_level} && $values{depth_level} == 3 ) {
                $values{name_url} = '+' . $values{name_url};
            }

            if ( exists $values{upper_region} && $values{upper_region} ) {

                my $region = $self->result_source->schema->resultset('Region')->find( { id => $values{upper_region} } );
                if ( !$region->subregions_valid_after ) {
                    $region->update(
                        {
                            subregions_valid_after => \'NOW()'
                        }
                    );
                }
            }

            my $var = $self->create( \%values );
            return $var;
        },
        update => sub {
            my %values = shift->valid_values;
            do { delete $values{$_} unless defined $values{$_} }
              for keys %values;

            $values{name_url} = $text2uri->translate( $values{name} ) if exists $values{name} && $values{name};
            $values{depth_level} = 3 if exists $values{upper_region} && $values{upper_region};

            $values{polygon_path} = undef unless exists $values{polygon_path};

            my $var = $self->find( delete $values{id} );
            if ( exists $values{name}
                && $var->depth_level == 3 ) {
                $values{name_url} = '+' . $values{name_url};
            }

            return unless keys %values;

            if ( exists $values{subregions_valid_after}
                && $var->subregions_valid_after ) {
                my $new = DateTimeX::Easy->new( $values{subregions_valid_after} );
                my $old = $var->subregions_valid_after;

                my @tables = qw/IndicatorValue IndicatorVariablesVariationsValue RegionVariableValue/;

                my $cmp = DateTime->compare( $new, $old );

                if ( $cmp == 1 ) {

                    # eh depois
                    # para todos levels = 3, apagar > $old & < $new
                    # para todos levels = 2, update active_value=true where generated_by_compute=null

                    my @subs = map { $_->id } $var->subregions->all;

                    for my $tbname (@tables) {
                        my $rs_pure = $self->result_source->schema->resultset($tbname);

                        $rs_pure->search(
                            {
                                region_id  => { 'in' => \@subs },
                                valid_from => { '>=' => $old->datetime, '<' => $new->datetime }
                            }
                        )->delete;

                        my $rs = $rs_pure->search(
                            {
                                region_id  => $var->id,
                                valid_from => { '>=' => $old->datetime, '<' => $new->datetime }
                            }
                        );

                        # apaga os ativos, **provavelmente** calculados
                        $rs->search( { generated_by_compute => 1 } )->delete;

                        # altera todos os nao computados para ativos
                        $rs->search( { generated_by_compute => undef } )->update( { active_value => 1 } );
                    }

                }
                elsif ( $cmp == -1 ) {

                    # eh antes

                    for my $tbname (@tables) {
                        my $rs_pure = $self->result_source->schema->resultset($tbname);

                        my $rs = $rs_pure->search(
                            {
                                region_id  => $var->id,
                                valid_from => { '>=' => $new->datetime }
                            }
                        );
                        $rs->search( { active_value => 1, generated_by_compute => undef } )
                          ->update( { active_value => 0 } );
                    }

                }

                # else: igual, entao nao precisa mudar nada

            }

            $var->update( \%values );

            $var->discard_changes;

            return $var;
        },

    };
}

1;

