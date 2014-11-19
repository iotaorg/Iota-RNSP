package Iota::Controller::RDF;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
use utf8;

sub base : Chained('/') PathPart('rdf') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{format_vs_contenttype} = {
        qw|
          ntriples text/plain
          nquads text/plain
          rdfxml application/xml
          rdfjson application/json
          ntriples-canonical text/plain
          turtle text/plain
          |
    };

    $c->stash->{serialize_format} =
      exists $c->req->params->{format} && exists $c->stash->{format_vs_contenttype}{ $c->req->params->{format} }
      ? $c->req->params->{format}
      : 'turtle';

    if ( $c->config->{rdf_domain} eq 'dynamic' ) {
        $c->config->{rdf_domain} = $c->model('DB::Network')->search( { rdf_identifier => 1 } )->next->domain_name;
    }

}

sub index : Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('/light_institute_load');
    $c->stash(
        custom_wrapper => 'iota-wrapper.tt',
        v2 => 1,
        custom_wrapper => 'site/iota_wrapper',
        c_req_path => 'rdf',
    );
}

__PACKAGE__->meta->make_immutable;

1;
