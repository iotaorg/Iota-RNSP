package Iota::Controller::API::V2::Cities;
use Moose;
use Iota::IndicatorFormula;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/institute_load') : PathPart('cities') : CaptureArgs(0) {
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub list_GET {
    my ( $self, $c ) = @_;

    $self->status_ok(
        $c,
        entity => {
            cities => map {
                my $r = $_;
                +{ ( map { $_ => $r->$_ } qw/id name uf pais latitude longitude name_uri summary/ ) }
            } $c->stash->{network_data}{cities}
        }
    );
}

1;

