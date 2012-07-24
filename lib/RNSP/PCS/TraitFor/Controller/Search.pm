package RNSP::PCS::TraitFor::Controller::Search;

use Moose::Role;
with 'Catalyst::TraitFor::Controller::DBIC::DoesPaging';

has 'ignored_params' => ( is => 'rw', default => sub { [qw(password api_key)] } );

around list_GET => sub {
    my $orig = shift;
    my $self = shift;
    my ($c)  = @_;

    if ( scalar keys %{ $c->request->params } > 1 ) {    # other than ? api_key = foo
        $c->stash->{collection} = $self->search( $c, $c->stash->{collection} );
    }

    $self->$orig(@_);

};

1;

