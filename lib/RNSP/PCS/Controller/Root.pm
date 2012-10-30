package RNSP::PCS::Controller::Root;
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

RNSP::PCS::Controller::Root - Root Controller for RNSP::PCS

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


sub prefeitura: Chained('root') PathPart('prefeitura') CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{find_role} = '_prefeitura';
}

sub prefeitura_pais: Chained('prefeitura') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $sigla ) = @_;
    $c->stash->{pais} = $sigla;
}

sub prefeitura_estado: Chained('prefeitura_pais') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $estado ) = @_;
    $c->stash->{estado} = $estado;
}

sub prefeitura_cidade: Chained('prefeitura_estado') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $cidade ) = @_;
    $c->stash->{cidade} = $cidade;
}

sub prefeitura_render: Chained('prefeitura_cidade') PathPart('') Args(0) {
    my ( $self, $c, $cidade ) = @_;
    $self->stash_tela_cidade($c);
}


sub movimento: Chained('root') PathPart('movimento') CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{find_role} = '_movimento';
}

sub movimento_pais: Chained('movimento') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $sigla ) = @_;
    $c->stash->{pais} = $sigla;
}

sub movimento_estado: Chained('movimento_pais') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $estado ) = @_;
    $c->stash->{estado} = $estado;
}

sub movimento_cidade: Chained('movimento_estado') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $cidade ) = @_;
    $c->stash->{cidade} = $cidade;
}

sub movimento_render: Chained('movimento_cidade') PathPart('') Args(0) {
    my ( $self, $c, $cidade ) = @_;
    $self->stash_tela_cidade($c);
}

sub stash_tela_cidade {
    my ( $self, $c ) = @_;

    my $city = $c->model('DB::City')->search({
        pais     => lc $c->stash->{pais},
        uf       => lc $c->stash->{estado},
        name_uri => lc $c->stash->{cidade}
    })->as_hashref->next;

    $c->forward('/error_404') unless $city;

    my $role_id = $c->model('DB::Role')->search( {name => $c->stash->{find_role}})->next;
    $c->forward('/error_404') unless $role_id;

    my $user = $c->model('DB::User')->search({
        city_id => $city->{id},
        'user_roles.role_id' => $role_id->id
    }, {  join  => 'user_roles' } )->as_hashref->next;

    $c->forward('/error_404') unless $user;


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
    my ( $self, $c ) = @_;
    $c->response->body('Page not found');
    $c->response->status(404);

}

sub error_500 : Private {
    my ( $self, $c ) = @_;
    $c->response->body('error');
    $c->response->status(500);

}


=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
}

=head1 AUTHOR

Thiago Rondon

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
