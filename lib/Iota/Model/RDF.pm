package Iota::Model::RDF;
use utf8;

sub rdf {
    require RDF::Helper;
    RDF::Helper->new(
        BaseInterface => 'RDF::Trine',
        namespaces => {
            dct => 'http://purl.org/dc/terms/',
            rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
            '#default' => "http://purl.org/rss/1.0/",
        },
        ExpandQNames => 1
    );
}

1;
