package RNSP::PCS::Data::Visitor;

use namespace::autoclean;
use Moose;
use Data::Printer;
extends 'Data::Visitor';

has current_path => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
    traits  => [qw(Array)],
    handles => {
        add_path_part => 'push',
        path_size     => 'count',
        _back         => 'pop',
        full_path     => [ join => '.' ],
        _clear_path   => 'clear',
    }
);

has final_value => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { +{} },
    clearer => '_clear_final_value'
);

sub visit_hash {
    my ( $self, $href ) = @_;
    for my $key ( keys %$href ) {
        if ( ref $href->{$key} eq 'HASH' ) {
            $self->add_path_part($key);
            $self->visit( $href->{$key} );
            $self->_back;
        }
        else {
            $self->path_size > 0
                ? $self->final_value->{ $self->full_path }{$key}
                = $href->{$key}
                : $self->final_value->{$key} = $href->{$key};
        }

    }
}

1;

