package Iota::View::HTML;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config(
    {
        TEMPLATE_EXTENSION => '.tt',
        ENCODING           => 'UTF-8',
        DEFAULT_ENCODING   => 'UTF-8',

        INCLUDE_PATH => [ Iota->path_to( 'root', 'src' ), Iota->path_to( 'root', 'lib' ) ],
        WRAPPER      => 'site/wrapper',
        ERROR        => 'error.tt',
        TIMER        => 0,
        render_die   => 1,

    }
);

=head1 NAME

Iota::View::HTML - Catalyst TTSite View

=head1 SYNOPSIS

See L<Iota>

=head1 DESCRIPTION

Catalyst TTSite View.

=head1 AUTHOR

renato,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

