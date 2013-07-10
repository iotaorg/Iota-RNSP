
package Iota::Controller::API::Region;

use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/root') : PathPart('regions') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{collection} = $c->model('DB::City');

}

sub object : Chained('base') : PathPart('') : CaptureArgs(3) {
    my ( $self, $c, $pais, $estado, $cidade ) = @_;
    $c->stash->{object} = $c->stash->{collection}->search_rs(
        {
            pais     => lc $pais,
            uf       => uc $estado,
            name_uri => lc $cidade
        }
    );

    $c->stash->{object}->count > 0 or $c->detach('/error_404');

    $c->stash->{collection} = $c->stash->{object}->next->regions;

}

sub list : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
}

sub list_GET {
    my ( $self, $c ) = @_;

    my @regions = $c->stash->{collection}->as_hashref->search(
        undef,
        {
            select => [qw/name name_url id upper_region/]
        }
    )->all;
    my $out = {};
    foreach my $reg (@regions) {
        my $x = $reg->{upper_region} || $reg->{id};
        push @{ $out->{$x} }, $reg;
    }

    undef @regions;
    foreach my $id ( keys %$out ) {
        my $pai;
        my @subs;
        foreach my $r ( @{ $out->{$id} } ) {
            if ( !$r->{upper_region} ) {
                $pai = $r;
            }
            else {
                push @subs, $r;
            }
        }
        @subs = sort { $a->{name} cmp $b->{name} } @subs;
        $pai->{subregions} = \@subs;
        push @regions, $pai;
    }
    @regions = sort { $a->{name} cmp $b->{name} } @regions;
    $self->status_ok( $c, entity => { regions => \@regions } );
}

1
