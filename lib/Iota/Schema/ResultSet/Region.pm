
package Iota::Schema::ResultSet::Region;

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


sub _build_verifier_scope_name { 'city.region' }


sub verifiers_specs {
   my $self = shift;
   return {
      create => Data::Verifier->new(
            profile => {
               name        => { required => 1, type => 'Str' },
               description => { required => 0, type => 'Str' },
               city_id     => { required => 1, type => 'Int' },
               created_by  => { required => 1, type => 'Int' },

               upper_region => {
                  required   => 0,
                  type       => 'Int',
                  post_check => sub {
                    my $r = shift;
                    my $axis =
                    $self->result_source->schema->resultset('Region')->find( { id => $r->get_value('upper_region') } );
                    return defined $axis;
                  }
               },

            },
      ),

      update => Data::Verifier->new(
            profile => {
               id          => { required => 1, type => 'Int' },
               name        => { required => 0, type => 'Str' },
               description => { required => 0, type => 'Str' },
               name_url    => { required => 0, type => 'Str' },

               upper_region => {
                  required   => 0,
                  type       => 'Int',
                  post_check => sub {
                    my $r = shift;
                    my $axis =
                    $self->result_source->schema->resultset('Region')->find( { id => $r->get_value('upper_region') } );
                    return defined $axis;
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

            $values{name_url} = $text2uri->translate( $values{name} );

            $values{depth_level} = 3 if exists $values{upper_region} && $values{upper_region};

            my $var = $self->create( \%values );

            my $data = Iota::IndicatorData->new(
                schema  => $self->result_source->schema
            );

            $data->upsert(
                region_id  => [ $var->id ]
            );

            return $var;
      },
      update => sub {
            my %values = shift->valid_values;
            do { delete $values{$_} unless defined $values{$_} }
              for keys %values;


            $values{name_url} = $text2uri->translate( $values{name} ) if exists $values{name} && $values{name};
            $values{depth_level} = 3 if exists $values{upper_region} && $values{upper_region};



            return unless keys %values;

            my $var = $self->find( delete $values{id} );

            $var->update( \%values );

            $var->discard_changes;

            return $var;
      },

   };
}

1;

