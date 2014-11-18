package Iota::Model::RDF;
use utf8;

sub rdf {
    require RDF::Helper;
    RDF::Helper->new(
        BaseInterface => 'RDF::Trine',
        namespaces => {
            dct => 'http://purl.org/dc/terms/',
            rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
            xsd => 'http://www.w3.org/2001/XMLSchema#',
        },
        ExpandQNames => 1
    );
}

1;
