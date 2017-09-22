
package Iota::Schema::ResultSet::UserBestPratice;

use namespace::autoclean;

use Moose;

extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use Text2URI;
my $text2uri = Text2URI->new();
use Iota::Types qw /VariableType DataStr/;

sub _build_verifier_scope_name { 'best_pratice' }
use JSON::XS;

use utf8;

sub verifiers_specs {
    my $self              = shift;
    my @duplicated_fields = (
        axis_dim1_id => {
            required   => 0,
            type       => 'Int',
            post_check => sub {
                my $r = shift;
                return 1 if $r->get_value('axis_dim1_id') == '0';
                my $axis =
                  $self->result_source->schema->resultset('AxisDim1')->find( { id => $r->get_value('axis_dim1_id') } );
                return defined $axis;
            }
        },
        axis_dim2_id => {
            required   => 0,
            type       => 'Int',
            post_check => sub {
                my $r = shift;
                return 1 if $r->get_value('axis_dim2_id') == '0';
                my $axis =
                  $self->result_source->schema->resultset('AxisDim2')->find( { id => $r->get_value('axis_dim2_id') } );
                return defined $axis;
            }
        },
        axis_dim3_id => {
            required   => 0,
            type       => 'Int',
            post_check => sub {
                my $r = shift;
                return 1 if $r->get_value('axis_dim3_id') == '0';
                my $axis =
                  $self->result_source->schema->resultset('AxisDim3')->find( { id => $r->get_value('axis_dim3_id') } );
                return defined $axis;
            }
        },

        image_user_file_id => {
            required   => 0,
            type       => 'Int',
            post_check => sub {
                my $r = shift;
                return 1 if $r->get_value('image_user_file_id') == '0';
                my $axis =
                  $self->result_source->schema->resultset('UserFile')
                  ->find( { id => $r->get_value('image_user_file_id') } );
                return defined $axis;
            }
        },
        thumbnail_user_file_id => {
            required   => 0,
            type       => 'Int',
            post_check => sub {
                my $r = shift;
                return 1 if $r->get_value('thumbnail_user_file_id') == '0';
                my $axis =
                  $self->result_source->schema->resultset('UserFile')
                  ->find( { id => $r->get_value('thumbnail_user_file_id') } );
                return defined $axis;
            }
        }
    );

    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                user_id => { required => 1, type => 'Int' },

                axis_id               => { required => 1, type => 'Int' },
                name                  => { required => 1, type => 'Str' },
                description           => { required => 0, type => 'Str' },
                methodology           => { required => 0, type => 'Str' },
                goals                 => { required => 0, type => 'Str' },
                schedule              => { required => 0, type => 'Str' },
                results               => { required => 0, type => 'Str' },
                contatcts             => { required => 0, type => 'Str' },
                sources               => { required => 0, type => 'Str' },
                repercussion          => { required => 0, type => 'Str' },
                tags                  => { required => 0, type => 'Str' },
                institutions_involved => { required => 0, type => 'Str' },
                reference_city        => { required => 0, type => 'Str' },
                @duplicated_fields
            },
        ),

        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                id                    => { required => 1, type => 'Int' },
                axis_id               => { required => 0, type => 'Int' },
                name                  => { required => 0, type => 'Str' },
                description           => { required => 0, type => 'Str' },
                methodology           => { required => 0, type => 'Str' },
                goals                 => { required => 0, type => 'Str' },
                schedule              => { required => 0, type => 'Str' },
                results               => { required => 0, type => 'Str' },
                contatcts             => { required => 0, type => 'Str' },
                sources               => { required => 0, type => 'Str' },
                repercussion          => { required => 0, type => 'Str' },
                tags                  => { required => 0, type => 'Str' },
                institutions_involved => { required => 0, type => 'Str' },
                reference_city        => { required => 0, type => 'Str' },
                @duplicated_fields

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

            for my $field (qw/ axis_dim1_id axis_dim2_id axis_dim3_id  image_user_file_id thumbnail_user_file_id/) {
                $values{$field} = undef if defined $values{$field} && $values{$field} eq '0';
            }

            my $var = $self->create( \%values );

            $var->discard_changes;

            if ( exists $ENV{SEND_BEST_PRATICE_EMAIL_TO}
                && $ENV{SEND_BEST_PRATICE_EMAIL_TO} ) {
                my $user = $var->user;

                my $net = $user->networks->first;

                my $queue = $self->result_source->schema->resultset('EmailsQueue');
                $queue->create(
                    {
                        to        => $ENV{SEND_BEST_PRATICE_EMAIL_TO},
                        subject   => 'Nova boa prática criada [% name %]',
                        template  => 'new_best_pratice.tt',
                        variables => encode_json(
                            {
                                ( map { $_ => $var->$_ } qw / id name name_url / ),

                                network_domain => $net ? $net->domain_name : '',

                                city_url => $user->city
                                ? ( join '/', $user->city->pais, $user->city->uf, $user->city->name_uri )
                                : '-',

                            }
                        ),
                        sent => 0
                    }
                );
            }
            return $var;
        },
        update => sub {
            my %values = shift->valid_values;

            do { delete $values{$_} unless defined $values{$_} }
              for keys %values;
            return unless keys %values;

            for my $field (qw/ axis_dim1_id axis_dim2_id axis_dim3_id  image_user_file_id thumbnail_user_file_id/) {
                $values{$field} = undef if defined $values{$field} && $values{$field} eq '0';
            }

            $values{reference_city} = undef unless $values{reference_city};

            $values{name_url} = $text2uri->translate( $values{name} )
              if exists $values{name} && $values{name};

            my $var = $self->find( delete $values{id} )->update( \%values );
            $var->discard_changes;
            return $var;
        },

    };
}

1;
