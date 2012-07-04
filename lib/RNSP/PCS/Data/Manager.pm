
package RNSP::PCS::Data::Manager;

use namespace::autoclean;
use Moose;

extends 'Data::Manager';
use Data::Printer;
use Data::Diver qw(Dive);
use RNSP::PCS::Data::Visitor;

has _input => ( is => 'ro', isa => 'HashRef', init_arg => 'input' );
has input => ( is => 'ro', isa => 'HashRef', init_arg => undef, lazy_build => 1 );

has actions => (
    is      => 'ro',
    traits  => ['Hash'],
    isa     => 'HashRef',
    default => sub { +{} },
    handles => {
        get_action_for => 'get',
        set_action_for => 'set',
    }
);

has outcomes => (
    is      => 'ro',
    traits  => ['Hash'],
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { +{} },
    handles => {
        get_outcome_for => 'get',
        set_outcome_for => 'set',
    }
);

sub _flatten {
    my ( $self, $href ) = @_;
    my $v = RNSP::PCS::Data::Visitor->new;
    $v->visit($href);
    return $v->final_value;
}

sub _build_input {
    my $self = shift;
    return $self->_flatten( $self->_input );
}

use Data::Printer;

sub apply {
    my ( $self, $input ) = @_;
    $input
        = ( $input || $self->input );
    my $verifiers = $self->verifiers;
    foreach my $key ( keys %$input ) {
        next
            unless exists $verifiers->{$key};
        my $results = $self->verify( $key, $input->{$key} );
        if ( my $action = $self->get_action_for($key) ) {
            $self->set_outcome_for( $key, $action->($results) )
                if $results->success;
        }
    }
    return 1;
}

sub errors {
    my $self = shift;
    my %errors;
    for my $msg ( @{ $self->messages->messages || [] } ) {
        $errors{ join( q/./, $msg->scope, $msg->subject, 'invalid' ) } = 1
            if $msg->msgid =~ /invalid/g;
        $errors{ join( q/./, $msg->scope, $msg->subject, 'missing' ) } = 1
            if $msg->msgid =~ /missing/g;
    }
    return \%errors;
}

around success => sub {
    my $orig = shift;
    my $self = shift;
    return !!( $self->$orig(@_) && scalar keys %{ $self->results } );
};
1;

