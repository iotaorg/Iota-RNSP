
package IOTA::PCS::Schema::ResultSet::City;

use namespace::autoclean;

use Moose;
use Text2URI;
my $text2uri = Text2URI->new();    # tem lazy la, don't worry

extends 'DBIx::Class::ResultSet';
with 'IOTA::PCS::Role::Verification';
with 'IOTA::PCS::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use JSON qw /encode_json/;
use Geo::Coder::Google;

has _geo_google => (
    is   => 'rw',
    isa  => 'Geo::Coder::Google::V3',

    lazy      => 1,
    builder   => '_build_geo_google',
);

sub _build_geo_google {
    Geo::Coder::Google->new(apiver => 3);
}

sub _build_verifier_scope_name { 'city' }

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            profile => {
                name                        => { required => 1, type => 'Str' },
                uf                          => { required => 1, type => 'Str', filter => [ 'trim', 'upper' ] },
                pais                        => { required => 0, type => 'Str' },
                latitude                    => { required => 0, type => 'Num' },
                longitude                   => { required => 0, type => 'Num' },
                telefone_prefeitura         => { required => 0, type => 'Str' },
                endereco_prefeitura         => { required => 0, type => 'Str' },
                bairro_prefeitura           => { required => 0, type => 'Str' },
                cep_prefeitura              => { required => 0, type => 'Str' },
                email_prefeitura            => { required => 0, type => 'Str' },
                nome_responsavel_prefeitura => { required => 0, type => 'Str' },
                summary                     => { required => 0, type => 'Str' },

            },
        ),

        update => Data::Verifier->new(
            profile => {
                id                          => { required => 1, type => 'Int' },
                name                        => { required => 1, type => 'Str' },
                uf                          => { required => 1, type => 'Str', filter => [ 'trim', 'upper' ] },
                pais                        => { required => 0, type => 'Str' },
                latitude                    => { required => 0, type => 'Num' },
                longitude                   => { required => 0, type => 'Num' },
                telefone_prefeitura         => { required => 0, type => 'Str' },
                endereco_prefeitura         => { required => 0, type => 'Str' },
                bairro_prefeitura           => { required => 0, type => 'Str' },
                cep_prefeitura              => { required => 0, type => 'Str' },
                email_prefeitura            => { required => 0, type => 'Str' },
                nome_responsavel_prefeitura => { required => 0, type => 'Str' },
                summary                     => { required => 0, type => 'Str' },
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

            $values{uf} = uc $values{uf};

            my $name_uri_o = $values{name_uri} = $text2uri->translate( $values{name} );
            my $name_o = $values{name};

            my $idx = 2;
            while (
                defined $self->search(
                    {
                        uf       => $values{uf},
                        name_uri => $values{name_uri},
                    }
                )->next
              ) {
                $values{name_uri} = $name_uri_o . '-' . $idx;
                $values{name}     = $name_o . '-' . $idx++;
            }


            my $location = $values{name} =~ /foo bar/i ? {} : eval{$self->_geo_google->geocode(
                location => $values{name} . ' ' . $values{uf} . ' Brasil'
            )};

            $values{latitude}  = $location->{geometry}{location}{lat}
                unless defined $values{latitude};
            $values{longitude} = $location->{geometry}{location}{lng}
                unless defined $values{longitude};

            my $var = $self->create( \%values );

            $var->discard_changes;
            return $var;
        },
        update => sub {
            my %values = shift->valid_values;

            do { delete $values{$_} unless defined $values{$_} }
              for keys %values;
            return unless keys %values;

            my $name_uri_o = $values{name_uri} = $text2uri->translate( $values{name} );
            my $name_o = $values{name};

            my $idx = 2;
            while (
                my $item = $self->search(
                    {
                        uf       => $values{uf},
                        name_uri => $values{name_uri},
                    }
                )->next
              ) {
                last if ( $item->id == $values{id} );
                $values{name_uri} = $name_uri_o . '-' . $idx;
                $values{name}     = $name_o . '-' . $idx++;
            }

            my $location = $values{name} =~ /foo bar/i ? {} : eval{$self->_geo_google->geocode(
                location => $values{name} . ' ' . $values{uf} . ' Brasil'
            )};
            $values{latitude}  = $location->{geometry}{location}{lat}
                unless defined $values{latitude};
            $values{longitude} = $location->{geometry}{location}{lng}
                unless defined $values{longitude};

            my $var = $self->find( delete $values{id} )->update( \%values );
            $var->discard_changes;
            return $var;
        },

    };
}

1;

