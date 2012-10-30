package RNSP::PCS::View::HTML;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config({
    TEMPLATE_EXTENSION => '.tt',
    ENCODING           => 'utf-8',
    DEFAULT_ENCODING    => 'utf-8',

    INCLUDE_PATH => [
        RNSP::PCS->path_to( 'root', 'src' ),
        RNSP::PCS->path_to( 'root', 'lib' )
    ],
    WRAPPER      => 'site/wrapper',
    ERROR        => 'error.tt',
    TIMER        => 0,
    render_die   => 1,
});

=head1 NAME

RNSP::PCS::View::HTML - Catalyst TTSite View

=head1 SYNOPSIS

See L<RNSP::PCS>

=head1 DESCRIPTION

Catalyst TTSite View.

=head1 AUTHOR

renato,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

