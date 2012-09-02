package RNSP::PCS::Model::Static;

use JSON::XS;
use namespace::autoclean;


use Moose;
extends 'Catalyst::Model';

has _eixos        => ( is => 'rw' );

sub eixos {
    my ( $self ) = @_;

return ('aa','bbb');

}


1;

