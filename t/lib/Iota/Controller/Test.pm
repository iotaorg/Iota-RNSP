
package Iota::Controller::Test;

use namespace::autoclean;

use Moose;
BEGIN { extends 'Catalyst::Controller'; }

__PACKAGE__->config( namespace => '' );

sub auto : Private {
    my ( $self, $c ) = @_;
}

1;

