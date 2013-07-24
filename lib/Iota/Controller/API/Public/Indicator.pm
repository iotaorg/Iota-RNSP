package Iota::Controller::API::Public::Indicator;

use Moose;

use Iota::IndicatorFormula;
use Iota::IndicatorChart::PeriodAxis;

use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/public/network_object') : PathPart('indicator') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    my @countries = @{ $c->stash->{network_data}{countries} };
    my @users_ids = @{ $c->stash->{network_data}{users_ids} };

    $c->stash->{collection} = $c->model('DB::Indicator')->search(
        {
            '-or' => [
                { visibility_level => 'public' },
                { visibility_level => 'country', visibility_country_id => { 'in' => \@countries } },
                { visibility_level => 'private', visibility_user_id => { 'in' => \@users_ids } },
                { visibility_level => 'restrict', 'indicator_user_visibilities.user_id' => { 'in' => \@users_ids } },
            ]
        },
        { join => 'indicator_user_visibilities' }
    );

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $self->status_bad_request( $c, message => 'invalid.argument' ), $c->detach
      unless $id =~ /^[0-9]+$/;

    $c->stash->{indicator} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
    $c->stash->{indicator_obj} = $c->stash->{indicator}->next;

    $c->detach('/error_404') unless $c->stash->{indicator_obj};

}

sub indicator : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

sub indicator_GET {
    my ( $self, $c ) = @_;

    $c->stash->{object} = $c->stash->{indicator};
    my $controller = $c->controller('API::Indicator');
    $controller->indicator_GET($c);


}


1;

