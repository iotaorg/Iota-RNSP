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

sub date4period {
    my ( $self, $c, $date, $period ) = @_;

    return Iota::IndicatorChart::PeriodAxis::get_label_of_period( $date, $period );
}

sub value4human {
    my ( $self, $c, $value, $variable_type, $measurement_unit ) = @_;

    return $value if ( $variable_type eq 'str' );

    my $pre = '';
    my $mid = '';
    my $end = '';
    if ( $variable_type eq 'num' ) {
        if ( $value =~ /^(\d+)\.(\d+)$/ ) {
            $pre = $1;
            $end = substr( $2, 0, 2 );
            $mid = ',';
        }
        else {
            $pre = $value;
        }
    }
    else {
        $pre = $value;
    }

    if ( length($pre) > 3 ) {
        $pre = reverse $pre;    # reverse the number's digits
        $pre =~ s/(\d{3})/$1\./g;    # insert dot every 3 digits, from beginning
        $pre = reverse $pre;         # Reverse the result
        $pre =~ s/^\.//;             # remove leading dot, if any
    }

    return "$pre$mid$end";
}

1;

