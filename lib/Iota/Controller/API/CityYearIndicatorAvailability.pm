package Iota::Controller::API::CityYearIndicatorAvailability;
use Moose;
BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

use utf8;

use JSON::XS;
use Encode qw(encode);

sub do : Chained('/light_institute_load') : PathPart('api/public/indicator-availability-city-year') : Args(0) :
  ActionClass('REST') {
}

sub do_GET {
    my ( $self, $c ) = @_;

    my $city_id = $c->req->params->{city_id} || '';
    $self->error( $c, 'invalid city_id' ) unless $city_id =~ /^[0-9]+$/;

    my $level = $c->req->params->{depth_level} || '';
    $self->error( $c, 'invalid depth_level' ) unless $level =~ /^[23]$/;

    my $periods = $c->req->params->{periods} || '';

    if ( $periods =~ /^[0-9]{4}$/ ) {
        $periods = ["$periods-01-01"];
    }
    else {
        $self->error( $c, 'invalid periods' ) unless my ($year) = $periods =~ /^([0-9]{4})-01-01$/;
        $periods = [ map { "$_-01-01" } $year .. $year + 3 ];
    }

    my $user_id = $c->model('DB::User')->search(
        {
            city_id      => $city_id,
            institute_id => $c->stash->{institute}->id
        }
    )->get_column('id')->next;
    $self->error( $c, 'missing user' ) unless $user_id;

    my $query = $c->model('DB::ViewIndicatorAvailabilityWithID')->search(
        {},
        {
            bind         => [ $level, $city_id, $user_id, $periods ],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    )->as_query;

    my @indicators_in_order = $c->model('DB::Indicator')->search(
        {
            variable_type => { 'in' => [qw/int num/] },
            id            => { in   => $query }
        },
        {

            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            columns      => [ 'id', 'name' ],
            order_by     => 'name'
        }
    )->all;


    $self->status_ok(
        $c,
        entity => {
            indicators => \@indicators_in_order,
        }
    );
}

sub error : Private {
    my ( $self, $c, $msg ) = @_;

    $self->status_bad_request( $c, message => $msg );
    $c->detach;
}

1;
