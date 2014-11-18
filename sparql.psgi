#!/usr/bin/perl

package FakeUser;

use Moose;

has 'cur_lang' => ( is => 'rw', isa => 'Str' );

no Moose;
__PACKAGE__->meta->make_immutable;

package FakeCatalyst;

use Moose;

has 'user'   => ( is => 'rw', isa => 'Any' );
has 'config' => ( is => 'ro', isa => 'Any' );

sub user_in_realm { 0 }

no Moose;
__PACKAGE__->meta->make_immutable;

package main;
use strict;
use warnings;
use utf8;

use FindBin qw($Bin);
use lib "$Bin/lib";


use Data::Dumper;
use Plack::Request;
use Plack::Builder;
use Carp qw(confess);
use RDF::Endpoint;
use LWP::MediaTypes qw(add_type);

add_type( 'application/rdf+xml' => qw(rdf xrdf rdfx) );
add_type( 'text/turtle' => qw(ttl) );
add_type( 'text/plain' => qw(nt) );
add_type( 'text/x-nquads' => qw(nq) );
add_type( 'text/json' => qw(json) );
add_type( 'text/html' => qw(html xhtml htm) );


$ENV{RDF_ENDPOINT_SHAREDIR} = "$Bin/root/static/rdf";
my $dump = "$Bin/root/static/built/rdf/";
mkdir($dump);

use Iota;
my $schema = Iota->model('DB');
my $rdf    = Iota->model('RDF')->rdf;

use RDF::Trine::Store;
use RDF::Trine::Model;

my $store = RDF::Trine::Store->new_with_config( {
      storetype => 'Hexastore',
} );

$rdf->model(RDF::Trine::Model->new( $store ));

my $rdf_domain = $schema->resultset('Network')->search({rdf_identifier => 1})->next->domain_name;
my $fake_c = FakeCatalyst->new( user => FakeUser->new( cur_lang => 'pt-br' ), config => Iota->config );

sub valid_values_for_lex_key {
    CatalystX::Plugin::Lexicon::valid_values_for_lex_key( $fake_c, @_ );
}

my $i = 0;
my $rs = $schema->resultset('Variable')->search(undef,{ rows =>1000,offset => 0  });

while (my $object = $rs->next){

    $i++;
    $object->populate_rdf(
        rdf => $rdf,
        rdf_domain => $rdf_domain,
        valid_values_for_lex_key => \&valid_values_for_lex_key
    );

    undef $object;
}
undef $rs;
undef $fake_c;
undef $schema;


use DDP; p $i;

my $fname = "$dump/dump.iota.n3";
open(my $f, '>', $fname) or die "cant open $fname $!";
$rdf->serialize( filename =>$f, format => 'ntriples');

`gzip -f $fname`;

my $end  = RDF::Endpoint->new( $rdf->model, {
    update => 0,
    html => {
        'resource_links' => 1,
        embed_images => 1
    }

} );

my $app = sub {
    my $env     = shift;
    my $req     = Plack::Request->new($env);
    my $resp    = $end->run( $req );
    return $resp->finalize;
};

builder {
    $app;
};

__END__

