package Iota::Controller::RDF::Indicator;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST' }
use utf8;

sub base : Chained('/rdf/base') PathPart('indicator') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{collection} = $c->model('DB::Indicator');
}

sub object : Chained('base') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $self->status_bad_request( $c, message => 'invalid.argument' ), $c->detach
      unless $id =~ /^[0-9]+$/;

    $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } )->next;
    $c->stash->{object} or $c->detach('/error_404_rdf');
}

sub show : Chained('object') PathPart('') Args(0) {
    my ( $self, $c, $id ) = @_;

    my $schema = $c->model('DB')->schema;

    my $object = $c->stash->{object};

    my $rdf = $c->model('RDF')->rdf;

    $object->populate_rdf(
        rdf => $rdf,
        rdf_domain => $c->config->{rdf_domain},
        valid_values_for_lex_key => sub { $c->valid_values_for_lex_key(@_) }
    );

    my $output = $rdf->serialize( format => $c->stash->{serialize_format} );

    $c->res->body($output);
    $c->res->header('Content-Type', $c->stash->{format_vs_contenttype}{$c->stash->{serialize_format}});
}

__PACKAGE__->meta->make_immutable;

1;
