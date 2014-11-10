package Iota::View::HTML;

use strict;
use base 'Catalyst::View::TT';
use Template::AutoFilter;
__PACKAGE__->config(
    {
        TEMPLATE_EXTENSION => '.tt',
        ENCODING           => 'UTF-8',
        DEFAULT_ENCODING   => 'UTF-8',

        CLASS        => 'Template::AutoFilter',
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

    return 'OK' if defined $value && $value == 1 && $variable_type eq 'str';
    return $value if $variable_type eq 'str';
    return 0 if $value < 0.0001;
    return $value if $value =~ /[a-z]/;

    my $pre = '';
    my $mid = '';
    my $end = '';

    if ( $variable_type eq 'num' ) {
        $value = sprintf('%f', $value);
        if ( $value =~ /^(\d+)\.(\d+)$/ ) {
            $pre = $1;
            $end = substr( $2, 0, 2 );
            if ( $end eq '00' && $2 ) {
                $end = substr( $2, 0, 3 );
            }
            $mid = ',';
        }
        else {
            $pre = $value;
        }
    }
    else {
        $pre = int $value;
    }

    if ( length($pre) > 3 ) {
        $pre = reverse $pre;         # reverse the number's digits
        $pre =~ s/(\d{3})/$1\./g;    # insert dot every 3 digits, from beginning
        $pre = reverse $pre;         # Reverse the result
        $pre =~ s/^\.//;             # remove leading dot, if any
    }

    return "$pre$mid$end";
}

sub l {
    my ( $self, $c, $text, @args ) = @_;
    return unless $text;

    return $c->loc( $text, @args ) || $text;
}

sub ymd_to_dmy {
    my ( $self, $c, $str ) = @_;
    return '' unless $str;

    $str = "$str";
    $str =~ s/(\d{4})-(\d{2})-(\d{2})/$3\/$2\/$1/;

    return $str;

}

sub ymd_to_human {
    my ( $self, $c, $str ) = @_;
    return '' unless $str;

    $str = "$str";
    $str =~ s/(\d{4})-(\d{2})-(\d{2})/$3\/$2\/$1/;

    $str =~ s/T/ /;

    if ( length $str > 16 ) {

        substr( $str, 16, 3 ) = '';
    }

    return substr( $str, 0, 10 + 6 );

}
1;

