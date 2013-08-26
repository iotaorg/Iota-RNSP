package Iota::Controller::Iota;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
use utf8;
use JSON::XS;

use DateTime;

sub base : Chained('/') PathPart(':iota') CaptureArgs(0) {
   my ($self, $c) = @_;
   $c->stash->{custom_wrapper} = 'iota-wrapper.tt';
}


sub env : Chained('base') PathPart('') CaptureArgs(0) {

}

sub status_load : Chained('env') PathPart('status') CaptureArgs(0) {
}


sub status : Chained('status_load') PathPart('') Args(0) {
    my ($self, $c) = @_;

    my @networks = $c->model('DB::Network')->search(undef, {
        prefetch => ['institute'],
        result_class => 'DBIx::Class::ResultClass::HashRefInflator'
    })->all;

    $c->stash->{networks} = \@networks;

    my @institutes = $c->model('DB::Institute')->search(undef, {
        result_class => 'DBIx::Class::ResultClass::HashRefInflator'
    })->all;

    $c->stash->{institutes} = \@institutes;

}


__PACKAGE__->meta->make_immutable;

1;
