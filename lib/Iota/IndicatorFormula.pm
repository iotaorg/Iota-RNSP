package Iota::IndicatorFormula;

use Moose;
use Math::Expression::Evaluator;

has formula => (
    is       => 'rw',
    isa      => 'Str',
    required => 1
);

has auto_parse => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { 1 }
);

has auto_check => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { 1 }
);

has schema => (
    is       => 'ro',
    isa      => 'Any',
    required => 1
);

has _math_ee => (
    is      => 'rw',
    isa     => 'Math::Expression::Evaluator',
    lazy    => 1,
    default => sub { Math::Expression::Evaluator->new }
);

has _compiled => (
    is  => 'rw',
    isa => 'Any',
);

has _variable => (
    is      => 'rw',
    isa     => 'ArrayRef[Int]',
    lazy    => 1,
    default => sub { [] },
    traits  => [qw(Array)],
    handles => {
        variables        => 'elements',
        _add_variable    => 'push',
        _variable_count  => 'count',
        _get_varaible    => 'get',
        _clear_variables => 'clear',
    }
);

has _variation_variable => (
    is      => 'rw',
    isa     => 'ArrayRef[Int]',
    lazy    => 1,
    default => sub { [] },
    traits  => [qw(Array)],
    handles => {
        variation_variables        => 'elements',
        _add_variation_variable    => 'push',
        _variation_variable_count  => 'count',
        _variation_get_varaible    => 'get',
        _clear_variation_variables => 'clear',
    }
);

has _is_string => (
    is      => 'rw',
    isa     => 'Bool',
    default => sub { 0 }
);

sub BUILD {
    my ($self) = @_;
    if ( $self->auto_parse ) { $self->parse }
}

sub parse {
    my ($self) = @_;
    my $formula = $self->formula;

    $self->_clear_variables;

    # caputar todas as variaveis
    $self->_add_variable($1)           while ( $formula =~ /\$(\d+)\b/go );
    $self->_add_variation_variable($1) while ( $formula =~ /\#(\d+)\b/go );

    # troca por V<ID>
    $formula =~ s/\$(\d+)\b/V$1/go;

    $formula =~ s/\#(\d+)\b/N$1/go;

    if ( $formula =~ /concatenar/io ) {
        $self->_is_string(1);
    }
    else {
        my $ee = $self->_math_ee;
        $self->_compiled( $ee->parse($formula)->compiled );
    }

    $self->check() if $self->auto_check;
}

sub evaluate_with_alias {
    my ( $self, %alias ) = @_;

    return 'NOT-SUPPORTED' if $self->_is_string;
    foreach ( $self->variables ) {
        return '-' unless defined $alias{V}{$_};
    }

    my $tmp;
    foreach my $var ( keys %alias ) {
        $tmp->{"$var$_"} = $alias{$var}{$_} for keys %{ $alias{$var} };
    }

    my $ret = eval { $self->_compiled()->($tmp) };
    if ( $@ && $@ =~ /by zero/ ) {
        return 0;
    }
    elsif ($@) {
        my $err = "$@";
        foreach my $var ( keys %alias ) {
            foreach my $varx ( keys %{ $tmp->{"$var$_"} } ) {
                $err .= ', ' . $varx . '=' . $tmp->{"$var$_"}{$varx};
            }
        }
        return $err;
    }
    return $ret;

}

sub evaluate {
    my ( $self, %vars ) = @_;

    foreach ( $self->variables ) {
        return '-' unless defined $vars{$_};
    }

    my $ret = eval {
            $self->_is_string
          ? $self->as_string(%vars)
          : $self->_compiled()->( { ( map { "V" . $_ => $vars{$_} } $self->variables ) } );
    };
    if ( $@ && $@ =~ /by zero/ ) {
        return 0;
    }
    elsif ($@) {
        my $err = "$@";
        $err .= join ', ', ( map { "V" . $_ . '=' . $vars{$_} } $self->variables );
        return $err;
    }

    return $ret;
}

sub as_string {
    my ( $self, %vars ) = @_;
    my $str = '';
    foreach ( $self->variables ) {

        $str .= $vars{$_} . ' ';
    }
    chop($str);
    return $str;
}

sub check {
    my ($self) = @_;

    my @variables = $self->schema->resultset('Variable')->search( { id => [ $self->variables ] } )->all;

    $self->_check_period( \@variables );

    $self->_check_only_numbers( \@variables ) unless $self->_is_string;

}

sub _check_period {
    my ( $self, $arr ) = @_;

    my $periods = {};
    $periods->{ $_->period() }++ foreach (@$arr);

    die 'variables with mixed period not allowed! IDs: ' . join( keys %$periods ) if keys %$periods > 1;
}

sub _check_only_numbers {
    my ( $self, $arr ) = @_;
    foreach (@$arr) {
        die "variable " . $_->id . " is a " . $_->type . " and it's not allowed!\n"
          if $_->type ne 'int' && $_->type ne 'num';
    }
}

sub as_human {
    my ($self) = @_;

    my $formula = $self->formula;

    my $sep = $formula =~ /CONCATENAR/i ? "\n" : ' ';
    $formula =~ s/CONCATENAR//i;

    if ( $formula =~ /\$/ ) {
        my @variables = $self->schema->resultset('Variable')->search( { id => [ $self->variables ] } )->all;
        foreach my $var (@variables) {
            my $name  = $var->name;
            my $varid = $var->id;

            while ( $formula =~ /\$$varid([^\d]|$)/ ) {
                $formula =~ s/\$$varid([^\d]|$)/$name$sep$1/;
            }
        }
    }

    if ( $formula =~ /\#/ ) {
        my @var_variables =
          $self->schema->resultset('IndicatorVariablesVariation')->search( { id => [ $self->variation_variables ] } )
          ->all;

        foreach my $var (@var_variables) {
            my $name  = $var->name;
            my $varid = $var->id;
            while ( $formula =~ /\#$varid([^\d]|$)/ ) {
                $formula =~ s/\#$varid([^\d]|$)/$name$sep$1/;
            }
        }
    }
    $formula =~ s/\b?\+\b?/ + /g;
    $formula =~ s/\b?\/\b?/ ÷ /g;
    $formula =~ s/\b?\*\b?/ × /g;
    $formula =~ s/\b?\-\b?/ - /g;

    $formula =~ s/^\s+//g;
    $formula =~ s/\s+$//g;
    $formula =~ s/ +/ /g;

    return $formula;
}

1;
