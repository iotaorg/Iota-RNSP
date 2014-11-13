package Iota::Controller::RDF::Variable;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST' }
use utf8;

sub base : Chained('/rdf/base') PathPart('variable') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{collection} = $c->model('DB::Variable');
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
    my $uri = 'http://' . $c->config->{rdf_domain} . $c->req->uri->path;

    my $rdf = $c->model('RDF')->rdf;

    # id => dct:Identifier
    $rdf->assert_literal( $uri, 'dct:Identifier', $object->id );

    # period => dct:accrualPeriodicity
    $rdf->assert_resource( $uri, 'dct:accrualPeriodicity', $schema->period_to_rdf($object->period) );

    # reserva memoria uma vez só
    my %str = ();

    # name => dct:title
    %str = $c->valid_values_for_lex_key( $object->name );

    $rdf->assert_literal( $uri, 'dct:title', $rdf->new_literal( $str{$_} , $_ )) for keys %str;

    # explanation => dct:description
    %str = $c->valid_values_for_lex_key( $object->explanation );
    $rdf->assert_literal( $uri, 'dct:description', $rdf->new_literal( $str{$_} , $_ )) for keys %str;

    $c->res->body($rdf->serialize( format => $c->stash->{serialize_formart} ));
    $c->res->header('Content-Type', $c->stash->{format_vs_contenttype}{$c->stash->{serialize_formart}});
}

__PACKAGE__->meta->make_immutable;

1;
