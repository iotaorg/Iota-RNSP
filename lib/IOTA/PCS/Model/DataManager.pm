package IOTA::PCS::Model::DataManager;

use namespace::autoclean;
use Data::Printer;
use IOTA::PCS::Data::Manager;

use Moose;
extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';

has data_manager => ( is => 'rw' );
has context      => ( is => 'rw' );

sub build_per_context_instance {
    my ( $self, $c ) = @_;

    my %verifiers = ();
    my %actions   = ();
    foreach my $name ( $c->models ) {
        next
            if $name =~ /(DataManager|file)/;
        my $model = $c->model($name);

        next unless $model->can('meta');
        next unless $model->meta->does_role('IOTA::PCS::Role::Verification');

        %verifiers = ( %verifiers, %{ $model->verifiers } );
        %actions   = ( %actions,   %{ $model->actions } );

    }
    $self->context($c);

    my $params = $c->req->params;
    $params = { %$params, %{ $c->req->data } }
        if $c->req->data;
    my $dm = IOTA::PCS::Data::Manager->new(
        input     => $params,
        verifiers => \%verifiers,
        actions   => \%actions
    );

    $self->data_manager($dm);

    $dm->apply;
    $c->stash->{error} = $dm->errors;
    return $dm;
}

sub apply {
    my $self = shift;
    my $dm   = $self->data_manager;

    $dm->apply;
    return 1
        if $dm->success;

    my $c = $self->context;
    my @params_keys
        = keys %{ $dm->input };
    my %errors
        = map { $_ => $dm->message_for_scope($_) }
        grep { defined $dm->message_for_scope($_) } @params_keys;

    @{ $c->stash->{error} }{ keys %errors } = values %errors;
    return 0;
}
1;

