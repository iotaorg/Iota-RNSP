package Iota::Controller::Root;
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

=head1 NAME

Iota::Controller::Root - Root Controller for Iota

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

   # Hello World
   $c->res->redirect('/frontend');
}


sub root: Chained('/') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;


}


sub network_object: Chained('root') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $rede ) = @_;

    my $net = $c->model('DB::Network')->search({
        name_url => $rede
    }, {
        prefetch => [{'current_user' => 'user_files'}]
    })->first;
    $c->detach('/error_404') unless $net;

    $c->stash->{network} = $net;
    $c->stash->{rede} = $net->name_url;
    my @files = $net->current_user->user_files;

    foreach my $file (sort {$b->created_at->epoch <=> $a->created_at->epoch} @files){
        if ($file->class_name eq 'custom.css'){
            $c->stash->{custom_css} = $file->public_url;
            last;
        }
    }

}

sub mapa_site: Chained('network_object') PathPart('mapa-do-site') Args(0) {
    my ( $self, $c, $cidade ) = @_;

    my @users = $c->stash->{network}->users->with_city->all;

    my @citys = $c->model('DB::City')->search({
        id => [
            map { $_->city_id } @users
        ]
    }, {order_by => ['pais', 'uf', 'name']})->as_hashref->all;

    my @indicators = $c->model('DB::Indicator')->search({
        indicator_roles => { like => '%' . $c->stash->{rede} . '%' }
    })->as_hashref->all;

     $c->stash(
        citys    => \@citys,
        indicators => \@indicators,
        template => 'mapa_site.tt'
    );
}


sub download_redir: Chained('root') PathPart('download') Args(0) {
    my ( $self, $c ) = @_;
    $c->res->redirect('/dados-abertos', 301);
}

sub download: Chained('root') PathPart('dados-abertos') Args(0) {
    my ( $self, $c, $cidade ) = @_;

    my @citys = $c->model('DB::City')->as_hashref->all;
    my @indicators = $c->model('DB::Indicator')->as_hashref->all;

     $c->stash(
        citys    => \@citys,
        indicators => \@indicators,
        template => 'download.tt',
        title => 'Dados abertos'
    );
}


sub network_page: Chained('network_object') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

sub network_pais: Chained('network_page') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $sigla ) = @_;
    $c->stash->{pais} = $sigla;
}

sub network_estado: Chained('network_pais') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $estado ) = @_;
    $c->stash->{estado} = $estado;
}

sub network_cidade: Chained('network_estado') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $cidade ) = @_;
    $c->stash->{cidade} = $cidade;
}

sub network_render: Chained('network_cidade') PathPart('') Args(0) {
    my ( $self, $c, $cidade ) = @_;
    $self->stash_tela_cidade($c);
}


sub network_indicator: Chained('network_cidade') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $indicator ) = @_;
    $c->stash->{indicator} = $indicator;
    $self->stash_tela_indicator($c);
}

sub network_indicator_render: Chained('network_indicator') PathPart('') Args(0) {
    my ( $self, $c, $cidade ) = @_;
     $c->stash(
        template => 'home_indicador.tt'
    );
}




sub network_index: Chained('network_page') PathPart('') Args(0) {
    my ( $self, $c, $sigla ) = @_;
    $c->stash(
        template => 'home_comparacao.tt'
    );
}



sub network_indicador: Chained('network_object') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $nome ) = @_;
    $self->stash_indicator($c, $nome);
}

sub network_indicador_render: Chained('network_indicador') PathPart('') Args(0) {
}




sub stash_indicator {
    my ( $self, $c, $nome ) = @_;

    my $indicator = $c->model('DB::Indicator')->search({
        name_url     => $nome
    })->as_hashref->next;


    $c->detach('/error_404') unless $indicator;
    $c->stash->{indicator} = $indicator;

    $c->stash( template => 'home_comparacao_indicador.tt',
        title => 'Dados do indicador ' . $indicator->{name}
    );
}





sub stash_tela_indicator {
    my ( $self, $c ) = @_;

    # carrega a cidade/user
    $self->stash_tela_cidade($c);

    # anti bug de quem chamar isso sem ler o fonte ^^
    delete $c->stash->{template};

    # TODO arruamr isso pra usar permissoes verdadeiras
    my $indicator = $c->model('DB::Indicator')->search({
        name_url     => $c->stash->{indicator},
        indicator_roles => {like => '%'.$c->stash->{network}->name_url.'%'}
    })->as_hashref->next;

    $c->detach('/error_404') unless $indicator;

    $c->stash->{indicator} = $indicator;
}


sub stash_tela_cidade {
    my ( $self, $c ) = @_;

    my $city = $c->model('DB::City')->search({
        pais     => lc $c->stash->{pais},
        uf       => uc $c->stash->{estado},
        name_uri => lc $c->stash->{cidade}
    })->as_hashref->next;

    $c->detach('/error_404') unless $city;

    my $user = $c->model('DB::User')->search({
        city_id => $city->{id},
        'me.active'  => 1,
        'me.network_id' => $c->stash->{network}->id
    } )->as_hashref->next;

    $c->detach('/error_404') unless $user;


    $c->stash(
        city => $city,
        user => $user,
        template => 'home_cidade.tt'
    );
}

sub default : Path {
    my ( $self, $c ) = @_;
    $c->response->body('Page not found');
    $c->response->status(404);
}

sub error_404 : Private {
    my ( $self, $c, $foo ) = @_;
    my $x = $c->req->uri;
    print STDERR "NOT FOUND " . $x->path,"\n";
    $c->response->body($x->path. ' Page not found');
    $c->response->status(404);

}

sub error_500 : Private {
    my ( $self, $c, $arg ) = @_;
    $c->response->body( $arg||'error');
    $c->response->status(500);

}


=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;

}

=head1 AUTHOR

Thiago Rondon

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
