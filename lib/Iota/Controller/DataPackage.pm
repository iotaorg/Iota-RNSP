
=head1 Gerar o arquivo de data package

=head2 Descrição

http://data.okfn.org/standards/data-package


=cut

package Iota::Controller::DataPackage;
use Moose;
use DateTime::Format::Pg;
use utf8;


BEGIN { extends 'Catalyst::Controller::REST' }
__PACKAGE__->config( default => 'application/json',
    content_type_stash_key => 'output_as'
);


sub _download {
    my ( $self, $c ) = @_;

    my @related     = ();
    my $ret         = {};
    my $description = '';
    my $title       = '';
    my $name        = '';
    my @keywords;
    $c->stash->{output_as} = 'application/json';

    my $data_rs = $c->model('DB::DownloadData')->search( { institute_id => $c->stash->{institute}->id },
        { result_class => 'DBIx::Class::ResultClass::HashRefInflator' } );

    my $data_rs_region =
      $c->model('DB')->resultset( exists $c->stash->{region} ? 'ViewDownloadVariablesRegion' : 'DownloadVariable' )
      ->search(
        { institute_id => $c->stash->{institute}->id },
        {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',

            exists $c->stash->{region}
            ? ( bind => [ ( $c->stash->{region}->id ) x 2 ] )
            : ()
        }
      );


    my $network = $c->stash->{network};
    my $current_updated = $network->created_at;

    $description .= $network->name;
    if ($c->stash->{cidade}){

        my $city = $c->stash->{city};
        my $city_db = $c->model('DB::City')->search(
            { 'me.id' => $city->{id} },
            { prefetch => ['country', 'state'] }
        )->next;


        $description .= ', ' . ('País') . ': ' . $city_db->country->name . ', ';
        $description .= ('Estado') . ': ' . $city_db->state->name . ', ';
        $description .= ('Cidade') . ': ' . $city->{name};


        $ret->{city}{$_} = $city_db->$_ for qw/id name country_id latitude longitude/;
        $ret->{city}{country} = $city_db->country->name;
        $ret->{city}{state} = $city_db->state->name;

        $title .= $ret->{city}{country} . ', ';
        $title .= $city->{name} . ' / ';
        $title .= $city->{uf};

        $name .= join '.', $c->stash->{pais}, $c->stash->{estado}, $c->stash->{cidade};
        push @keywords, $city_db->country->name, $city_db->state->name, $city_db->name;

        $current_updated = $city_db->created_at;
    }

    if ($c->stash->{region}){
        $description .= ( $c->stash->{region_classification_name}{ $c->stash->{region}->depth_level } ) . ': ' . $c->stash->{region}->name;
        $title .= ' - ' . $c->stash->{region}->name;

        $name .= '_' . $c->stash->{region}->name_url;
        push @keywords, $c->stash->{region}->name;
    }


    if ($c->stash->{indicator}){
        $description .= ('Indicador') . ': ' . $c->stash->{indicator}{name};

        $title .= ': ' . $c->stash->{indicator}{name};
        $name .= '_' . $c->stash->{indicator}{name_url};
        push @keywords, $name;
    }

    $name = $network->name_url unless $name;
    $title = $network->name unless $title;

    if ( $c->stash->{cidade} ) {

        # procula pela cidade, se existir.
        my $cities = $c->model('DB::City')->as_hashref->search(
            {
                pais     => lc $c->stash->{pais},
                uf       => uc $c->stash->{estado},
                name_uri => lc $c->stash->{cidade}
            }
        )->next;

        my $id = $cities ? $cities->{id} : -9012345;    # download vazio
        $data_rs        = $data_rs->search( { city_id => $id } );

         my $user = $c->model('DB::User')->as_hashref->search(
            {
                city_id                    => $id,
                'network_users.network_id' => $network->id
            },
            { join => 'network_users' }
        )->next;

        $data_rs_region = $data_rs_region->search( { user_id => $user ? $user->{id} : -9012345 } );

    }

    if ( exists $c->stash->{indicator} ) {
        $data_rs = $data_rs->search( { indicator_id => $c->stash->{indicator}{id} } );


        $data_rs_region = $data_rs_region->search(
            {
                variable_id => {
                    'in' => [
                        (
                            map { $_->variable_id }
                              $c->model('DB::IndicatorVariable')
                              ->search( { indicator_id => $c->stash->{indicator}{id} } )->all
                        ),

                        (
                            map { -( $_->id ) }
                              $c->model('DB::IndicatorVariation')
                              ->search( { indicator_id => $c->stash->{indicator}{id} } )->all
                        )
                    ]
                }
            }
        );

    }

    if ( exists $c->stash->{region} ) {
        $data_rs = $data_rs->search( { region_id => $c->stash->{region}->id } );

        $data_rs_region = $data_rs_region->search( { region_id => $c->stash->{region}->id } );
    }
    else {
        $data_rs = $data_rs->search( { region_id => undef } );
    }


    if (
        # sem indicador, mas com cidade
        # related = todos os indicadores
        !exists $c->stash->{indicator} &&
         exists $c->stash->{cidade}
    ){
        my @hide_indicator =
        map { $_->indicator_id }
            $c->model('DB::User')->find($c->stash->{user}{id})->
            user_indicator_configs->search( { hide_indicator => 1 } )->all;

        my $rs = $c->model('DB::Indicator')->search(
            {
                'me.id' => { '-not_in' => \@hide_indicator }
            },
            {
                select => [qw/name_url/],
                result_class => 'DBIx::Class::ResultClass::HashRefInflator'
            }
        );

        my $base_rel = join '/', 'http:/', $network->domain_name, $c->stash->{pais}, $c->stash->{estado}, $c->stash->{cidade};

        if ($c->stash->{region}){
            $base_rel .= '/' . $c->stash->{region}->name_url;
        }

        while ( my $indicator = $rs->next ) {
            push @related, "$base_rel/$indicator->{name_url}";
        }
    }

    my $last1 = $data_rs->get_column('updated_at')->max();
    my $last2 = $data_rs_region->get_column('updated_at')->max();

    $last1 = DateTime::Format::Pg->parse_datetime($last1)
        if $last1;

    $last2 = DateTime::Format::Pg->parse_datetime($last2)
        if $last2;

    my $last_updated =
        ref $last1 eq 'DateTime' &&
        ref $last2 eq 'DateTime'
        ?
            DateTime->compare( $last1, $last2 ) == 1
            ? $last1->datetime
            : $last2->datetime
        :
            $last1 ? $last1->datetime :
            $last2 ? $last2->datetime : undef;

    my $base_url = 'http://' . $network->domain_name . $c->req->uri->path;
    $base_url =~ s/\/datapackage.json$//;

    my $name_arq = 'indicadores';
    $name_arq = 'dados' if ( exists $c->stash->{indicator} );


    my $institute = $c->stash->{institute};

    $ret = {
        %$ret,
        name        =>  $name,
        title       =>  $title,
        (author => $institute->datapackage_autor) x!!$institute->datapackage_autor,
        (author_email => $institute->datapackage_autor_email) x!!$institute->datapackage_autor_email,

        description =>  $description,
        licenses =>  [
            ({
                id  => $institute->license,
                url => $institute->license_url
            }) x!! $institute->license
        ],
        keywords     =>  [ @keywords ],
        version      =>  "iota-v$Iota::VERSION",
        last_updated =>  ($last_updated ? $last_updated : $current_updated->ymd . ' ' . $current_updated->hms ),


        related => \@related,

        (image => $institute->image_url) x!!$institute->image_url,

        resources => ($last_updated ? [

            {
                name => ('Valores por variável'),
                path => "$base_url/variaveis.csv",
                mediatype => 'text/csv',
                format    => 'csv'

            },
            {
                name => ('Valores por indicador'),
                path => "$base_url/$name_arq.csv",
                mediatype => 'text/csv',
                format    => 'csv'
            }
        ] : [] )
    };



    if ($@) {
        $self->status_bad_request( $c, message => "$@", );
    }
    else {
        $self->status_ok( $c, entity => $ret );
    }
}


for my $chain (
    qw/institute_load network_cidade cidade_regiao network_indicator network_indicador cidade_regiao_indicator/) {
    for my $tipo (qw/json/) {
        eval( "
            sub chain_${chain}_${tipo} : Chained('/$chain') : PathPart('datapackage.$tipo') : CaptureArgs(0) {
                my ( \$self, \$c ) = \@_;
                \$c->stash->{type} = '$tipo';
            }

            sub render_${chain}_${tipo} : Chained('chain_${chain}_${tipo}') : PathPart('') : Args(0) {
                my ( \$self, \$c ) = \@_;
                \$self->_download(\$c);
            }
        " );
    }
}
1;

