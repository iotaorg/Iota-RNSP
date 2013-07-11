
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
                        return defined $axis;
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

            $var->update( \%values );

            $var->discard_changes;

            return $var;
        },

    };
}

1;

