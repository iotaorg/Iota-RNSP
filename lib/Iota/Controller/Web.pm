package Iota::Controller::Web;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
use utf8;
use JSON::XS;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config( namespace => '' );

sub institute_load : Chained('root') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    my $domain = $c->req->uri->host;

    my $net = $c->model('DB::Network')->search( { domain_name => $domain }, { prefetch => 'current_user' } )->first;
    $c->detach( '/error_404', [ 'Nenhuma rede para o dominio ' . $domain . '!' ] ) unless $net;

    $c->stash->{network} = $net;

    $c->stash->{institute} = $net->institute;

    if ( $net->current_user ) {
        my @files = $net->current_user->user_files;

        foreach my $file ( sort { $b->created_at->epoch <=> $a->created_at->epoch } @files ) {
            if ( $file->class_name eq 'custom.css' ) {
                $c->stash->{custom_css} = $file->public_url;
                last;
            }
        }
    }

    my @users = $c->stash->{network}->users->all;

    my @cities =
      $c->model('DB::City')
      ->search( { id => [ map { $_->city_id } @users ] }, { order_by => [ 'pais', 'uf', 'name' ] } )->as_hashref->all;

    $c->stash->{network_data} = {
        countries => [
            do {
                my %seen;
                grep { !$seen{$_}++ } map { $_->{country_id} } @cities;
              }
        ],
        users_ids => [
            do {
                my %seen;
                grep { !$seen{$_}++ } map { $_->id } @users;
              }
        ],
        cities => \@cities
    };

}

sub mapa_site : Chained('institute_load') PathPart('mapa-do-site') Args(0) {
    my ( $self, $c ) = @_;

    my @countries = @{ $c->stash->{network_data}{countries} };
    my @users_ids = @{ $c->stash->{network_data}{users_ids} };

    my @indicators = $c->model('DB::Indicator')->search(
        {
            '-or' => [
                { visibility_level => 'public' },
                { visibility_level => 'country', visibility_country_id => { 'in' => \@countries } },
                { visibility_level => 'private', visibility_user_id => { 'in' => \@users_ids } },
                { visibility_level => 'restrict', 'indicator_user_visibilities.user_id' => { 'in' => \@users_ids } },
            ]
        },
        { join => 'indicator_user_visibilities', order_by => 'me.name' }
    )->as_hashref->all;

    $c->stash(
        cities     => $c->stash->{network_data}{cities},
        indicators => \@indicators,
        template   => 'mapa_site.tt'
    );
}

sub download_redir : Chained('root') PathPart('download') Args(0) {
    my ( $self, $c ) = @_;
    $c->res->redirect( '/dados-abertos', 301 );
}

sub download : Chained('institute_load') PathPart('dados-abertos') Args(0) {
    my ( $self, $c ) = @_;

    $self->mapa_site($c);

    $c->stash(
        template => 'download.tt',
        title    => 'Dados abertos'
    );
}

sub network_page : Chained('institute_load') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

sub network_pais : Chained('network_page') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $sigla ) = @_;
    $c->stash->{pais} = $sigla;
}

sub network_estado : Chained('network_pais') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $estado ) = @_;
    $c->stash->{estado} = $estado;
}

sub network_cidade : Chained('network_estado') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $cidade ) = @_;
    $c->stash->{cidade} = $cidade;

    $self->stash_tela_cidade($c);

    $c->stash->{title} = $c->stash->{city}{name} . ', ' . $c->stash->{city}{uf};
}

sub cidade_regiao : Chained('network_cidade') PathPart('regiao') CaptureArgs(1) {
    my ( $self, $c, $regiao ) = @_;
    $c->stash->{regiao_url} = $regiao;

    $self->stash_tela_regiao($c);

    $c->stash->{title} = $c->stash->{region}->name . ' - ' . $c->stash->{city}{name} . ', ' . $c->stash->{city}{uf};
}


sub cidade_regiao_indicator : Chained('cidade_regiao') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $indicator ) = @_;

    $c->stash->{indicator} = $indicator;
    $self->stash_tela_indicator($c);

    $c->stash(
        template   => 'home_region_indicator.tt'
    );
}


sub cidade_regiao_indicator_render : Chained('cidade_regiao_indicator') PathPart('') Args(0) {
}

sub cidade_regiao_render : Chained('cidade_regiao') PathPart('') Args(0) {
}

sub network_render : Chained('network_cidade') PathPart('') Args(0) {
}

sub user_page : Chained('network_cidade') PathPart('pagina') CaptureArgs(2) {
    my ( $self, $c, $page_id, $title ) = @_;

    my $page = $c->model('DB::UserPage')->search(
        {
            id      => $page_id,
            user_id => $c->stash->{user}{id}
        }
    )->as_hashref->next;

    $c->detach('/error_404') unless $page;
    $c->stash->{page} = $page;

    $c->stash(
        template => 'home_cidade_pagina.tt',
        title    => $page->{title}
    );

}

sub user_page_render : Chained('user_page') PathPart('') Args(0) {
    my ( $self, $c ) = @_;
}

sub network_indicator : Chained('network_cidade') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $indicator ) = @_;
    $c->stash->{indicator} = $indicator;
    $self->stash_tela_indicator($c);
}

sub network_indicator_render : Chained('network_indicator') PathPart('') Args(0) {
    my ( $self, $c, $cidade ) = @_;
    $c->stash( template => 'home_indicador.tt' );
}

sub network_indicador : Chained('institute_load') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $nome ) = @_;
    $self->stash_indicator( $c, $nome );
}

sub network_indicador_render : Chained('network_indicador') PathPart('') Args(0) {
}

sub stash_indicator {
    my ( $self, $c, $nome ) = @_;

    my $indicator = $c->model('DB::Indicator')->search( { name_url => $nome } )->as_hashref->next;

    $c->detach('/error_404') unless $indicator;
    $c->stash->{indicator} = $indicator;

    $c->stash(
        template => 'home_comparacao_indicador.tt',
        title    => 'Dados do indicador ' . $indicator->{name}
    );
}

sub stash_tela_indicator {
    my ( $self, $c ) = @_;

    # carrega a cidade/user
    $self->stash_tela_cidade($c);

    # anti bug de quem chamar isso sem ler o fonte ^^
    delete $c->stash->{template};

    my @countries = @{ $c->stash->{network_data}{countries} };
    my @users_ids = @{ $c->stash->{network_data}{users_ids} };

    my $indicator = $c->model('DB::Indicator')->search(
        {
            name_url => $c->stash->{indicator},
            '-or'    => [
                { visibility_level => 'public' },
                { visibility_level => 'country', visibility_country_id => { 'in' => \@countries } },
                { visibility_level => 'private', visibility_user_id => { 'in' => \@users_ids } },
                { visibility_level => 'restrict', 'indicator_user_visibilities.user_id' => { 'in' => \@users_ids } },
            ]
        },
        { join => 'indicator_user_visibilities' }
    )->as_hashref->next;
    $c->detach( '/error_404', ['Indicador não encontrado!'] ) unless $indicator;

    $c->stash->{indicator} = $indicator;

    $c->stash->{title} = $indicator->{name} . ' de ' . $c->stash->{city}{name} . ', ' . $c->stash->{city}{uf};
}

sub stash_tela_cidade {
    my ( $self, $c ) = @_;

    my $city = $c->model('DB::City')->search(
        {
            pais     => lc $c->stash->{pais},
            uf       => uc $c->stash->{estado},
            name_uri => lc $c->stash->{cidade}
        },
        { prefetch => 'regions' }
    )->as_hashref->next;

    $c->detach('/error_404') unless $city;

    $self->_setup_regions_level( $c, $city ) if ( $city->{regions} && @{ $city->{regions} } > 0 );

    my $user = $c->model('DB::User')->search(
        {
            city_id         => $city->{id},
            'me.active'     => 1,
            'me.network_id' => $c->stash->{network}->id
        }
    )->next;

    $c->detach('/error_404') unless $user;

    $c->stash->{user_obj} = $user;
    my $public = $c->controller('API::UserPublic')->user_public_load($c);
    $c->stash( public => $public );

    my @files = $user->user_files;

    foreach my $file ( sort { $b->created_at->epoch <=> $a->created_at->epoch } @files ) {
        if ( $file->class_name eq 'custom.css' ) {
            $c->assets->include( $file->public_url, 9999 );
            last;
        }
    }

    my $menurs = $user->user_menus->search(
        undef,
        {
            order_by => [ { '-asc' => 'me.position' }, 'me.id' ],
            prefetch => 'page'
        }
    );
    $self->_load_menu( $c, $menurs );

    $self->_load_variables( $c, $user );

    $user = { $user->get_inflated_columns };
    $c->stash(
        city     => $city,
        user     => $user,
        template => 'home_cidade.tt',
    );
}

sub _setup_regions_level {
    my ( $self, $c, $city ) = @_;

    my $out = {};
    foreach my $reg ( @{ $city->{regions} } ) {
        my $x = $reg->{upper_region} || $reg->{id};
        push @{ $out->{$x} }, $reg;
    }

    my @regions;
    foreach my $id ( keys %$out ) {
        my $pai;
        my @subs;
        foreach my $r ( @{ $out->{$id} } ) {
            $r->{url} = $c->uri_for( $self->action_for('cidade_regiao_render'),
                [ $city->{pais}, $city->{uf}, $city->{name_uri}, $r->{name_url} ] )->as_string;

            if ( !$r->{upper_region} ) {
                $pai = $r;
            }
            else {
                push @subs, $r;
            }
        }
        $pai->{subregions} = \@subs;
        push @regions, $pai;
    }

    $city->{regions} = \@regions;
}

sub _load_variables {
    my ( $self, $c, $user ) = @_;

    my @admins_ids = map { $_->id } $c->stash->{network}->users->search(
        {
            city_id => undef    # admins
        }
    )->all;
    my $mid = $user->id;

    my $var_confrs = $c->model('DB::UserVariableConfig')->search( { user_id => [ @admins_ids, $mid ] } );

    my $aux = {};
    while ( my $conf = $var_confrs->next ) {
        push @{ $aux->{ $conf->variable_id } }, [ $conf->display_in_home, $conf->user_id, $conf->position ];
    }

    my $show  = {};
    my $order = {};

    # a configuracao do usuario sempre tem preferencia sob a do admin
    while ( my ( $vid, $wants ) = each %$aux ) {

        if ( @$wants == 1 && $wants->[0][0] ) {
            $order->{$vid} = $wants->[0][2];
            $show->{$vid}++ and last;
        }

        foreach my $conf (@$wants) {
            if ( $conf->[1] == $mid && $conf->[0] ) {

                $order->{$vid} = $conf->[2];
                $show->{$vid}++ and last;
            }
        }

    }

    my $values = $user->variable_values->search(
        { variable_id => { 'in' => [ keys %$show ] }, },
        {
            order_by => [            { -desc => 'valid_from' } ],
            prefetch => { 'variable' => 'measurement_unit' }
        }
    );

    my %exists;
    my @variables;
    while ( my $val = $values->next ) {
        next if $exists{ $val->variable_id }++;

        push @variables, $val;
    }

    @variables = sort { $order->{ $a->variable_id } <=> $order->{ $b->variable_id } } @variables;

    $c->stash( user_basic_variables => \@variables );
}

sub _load_menu {
    my ( $self, $c, $menurs ) = @_;

    my $menu = {};
    my @menu_out;

    while ( my $m = $menurs->next ) {
        my $pai = $m->menu_id || $m->id;
        push( @{ $menu->{$pai} }, $m );
    }

    while ( my ( $id, $rows ) = each %$menu ) {
        my $menu;
        for my $menurs (@$rows) {
            if ( !$menurs->menu_id ) {
                $menu = {
                    title => $menurs->title,
                    (
                        link => $menurs->page_id
                        ? $c->uri_for(
                            $self->action_for('user_page_render'),
                            [
                                $c->stash->{pais}, $c->stash->{estado}, $c->stash->{cidade},
                                $menurs->page_id,  $menurs->page->title_url,
                            ]
                          )
                        : ''
                    )
                };
                push @menu_out, $menu;
            }
        }

        for my $menurs (@$rows) {
            if ( $menurs->menu_id ) {
                push @{ $menu->{subs} },
                  {
                    title => $menurs->title,
                    (
                        link => $menurs->page_id
                        ? $c->uri_for(
                            $self->action_for('user_page_render'),
                            [
                                $c->stash->{pais}, $c->stash->{estado}, $c->stash->{cidade},
                                $menurs->page_id,  $menurs->page->title_url,
                            ]
                          )
                        : ''
                    )
                  };
            }
        }
    }

    $c->stash( menu => \@menu_out, );

}

sub stash_tela_regiao {
    my ( $self, $c ) = @_;

    my $region = $c->model('DB::Region')->search(
        {
            name_url => lc $c->stash->{regiao_url},
            city_id  => $c->stash->{city}{id}
        }
    )->next;

    $c->detach('/error_404') unless $region;
    $c->stash(
        region   => $region,
        template => 'home_region.tt',
    );

    if ( $region->depth_level == 2 ) {
        my @subregions = $c->model('DB::Region')->search(
            {
                city_id      => $c->stash->{city}{id},
                upper_region => $region->id
            }
        )->all;
        $c->stash->{subregions} = \@subregions;
    }

    $self->_load_region_variables($c);
}

sub _load_region_variables {
    my ( $self, $c ) = @_;

    my $region = $c->stash->{region};
    my @admins_ids = map { $_->id } $c->stash->{network}->users->search(
        {
            city_id => undef    # admins
        }
    )->all;
    my $mid = $c->stash->{user}{id};
    my $var_confrs = $region->user_variable_region_configs->search( { user_id => [ @admins_ids, $mid ] } );

    my $aux = {};
    while ( my $conf = $var_confrs->next ) {
        push @{ $aux->{ $conf->variable_id } }, [ $conf->display_in_home, $conf->user_id, $conf->position ];
    }

    my $show  = {};
    my $order = {};

    # a configuracao do usuario sempre tem preferencia sob a do admin
    while ( my ( $vid, $wants ) = each %$aux ) {

        if ( @$wants == 1 && $wants->[0][0] ) {
            $order->{$vid} = $wants->[0][2];
            $show->{$vid}++ and last;
        }

        foreach my $conf (@$wants) {
            if ( $conf->[1] == $mid && $conf->[0] ) {

                $order->{$vid} = $conf->[2];
                $show->{$vid}++ and last;
            }
        }

    }

    my $values = $region->region_variable_values->search(
        {
            'me.variable_id' => { 'in' => [ keys %$show ] },
            'me.user_id'     => $mid
        },
        {
            order_by => [            { -desc => 'me.valid_from' } ],
            prefetch => { 'variable' => 'measurement_unit' }
        }
    );

    my %exists;
    my @variables;
    while ( my $val = $values->next ) {
        next if $exists{ $val->variable_id }++;

        push @variables, $val;
    }

    @variables = sort { $order->{ $a->variable_id } <=> $order->{ $b->variable_id } } @variables;

    $c->stash( basic_variables => \@variables );

}

__PACKAGE__->meta->make_immutable;

1;
