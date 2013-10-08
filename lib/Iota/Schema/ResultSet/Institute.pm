
package Iota::Schema::ResultSet::Institute;

use namespace::autoclean;

use Moose;

extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Data::Verifier;

sub _build_verifier_scope_name { 'institute' }

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                name        => { required => 1, type => 'Str' },
                short_name  => { required => 1, type => 'Str' },
                description => { required => 0, type => 'Str' },

                users_can_edit_value  => { required => 0, type => 'Bool' },
                users_can_edit_groups => { required => 0, type => 'Bool' },
                can_use_custom_css    => { required => 0, type => 'Bool' },
                can_use_custom_pages  => { required => 0, type => 'Bool' },

                can_use_regions       => { required => 0, type => 'Bool' },
                can_create_indicators   => { required => 0, type => 'Bool' },
                fixed_indicator_axis_id => { required => 0, type => 'Int' },
            },
        ),

        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                id          => { required => 1, type => 'Int' },
                name        => { required => 0, type => 'Str' },
                short_name  => { required => 0, type => 'Str' },
                description => { required => 0, type => 'Str' },

                users_can_edit_value  => { required => 0, type => 'Bool' },
                users_can_edit_groups => { required => 0, type => 'Bool' },
                can_use_custom_css    => { required => 0, type => 'Bool' },
                can_use_custom_pages  => { required => 0, type => 'Bool' },
                can_use_regions       => { required => 0, type => 'Bool' },

                can_create_indicators   => { required => 0, type => 'Bool' },
                fixed_indicator_axis_id => { required => 0, type => 'Int' },
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

            if (exists $values{can_use_regions} && $values{can_use_regions} == 0){
               $var->users->update({regions_enabled => 0});
            }

            return $var;
        },

    };
}

1;

