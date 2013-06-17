package Iota::Controller::API::City::Region;

use Moose;
use JSON qw (encode_json);
BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/city/object') : PathPart('region') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{city}       = $c->stash->{object}->next;
    $c->stash->{collection} = $c->stash->{city}->regions;

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
    $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub region : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

=pod

=encoding utf-8

GET /api/city/$id/region/$id


=cut

sub region_GET {
    my ( $self, $c ) = @_;
    my $object_ref = $c->stash->{object}->search( undef, { prefetch => 'upper_region' } )->as_hashref->next;

    $self->status_ok(
        $c,
        entity => {
            (
                map { $_ => $object_ref->{$_} }
                  qw(
                  name name_url description depth_level automatic_fill polygon_path
                  )
            ),
            city => {
                (
                    map { $_ => $c->stash->{city}->$_ }
                      qw(
                      name name_uri uf pais
                      )
                ),
            },
            upper_region => $object_ref->{upper_region}
            ? {
                id       => $object_ref->{upper_region}{id},
                name     => $object_ref->{upper_region}{name},
                name_url => $object_ref->{upper_region}{name_url},
              }
            : undef
        }
    );
}

=pod

POST /api/city/$id/region/$id

Retorna:


=cut

sub region_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(user admin superadmin ));

    my $obj_rs = $c->stash->{object}->next;

    my $param = $c->req->params->{city}{region}{update};
    $param->{id} = $obj_rs->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $obj = $dm->get_outcome_for('city.region.update');

    $self->status_accepted(
        $c,
        location => $c->uri_for( $self->action_for('region'), [ $c->stash->{city}->id, $obj->id ] )->as_string,
        entity => { id => $obj->id }
      ),

      $c->detach;
}

=pod

Apaga o registro da tabela CityRegion

DELETE /api/city/$id/region/$id

Retorna: No-content ou Gone

=cut

sub region_DELETE {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(user admin superadmin ));

    my $obj = $c->stash->{object}->next;
    $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

    $obj->delete;

    $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}

=pod

POST /api/city/$id/region


=cut

sub list_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(user admin superadmin ));

    my $param = $c->req->params->{city}{region}{create};
    $param->{city_id}    = $c->stash->{city}->id;
    $param->{created_by} = $c->user->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $object = $dm->get_outcome_for('city.region.create');

    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('region'), [ $c->stash->{city}->id, $object->id ] )->as_string,
        entity => { id => $object->id }
    );

}

sub list_GET {
    my ( $self, $c ) = @_;

    my @list = $c->stash->{collection}->search( undef, { prefetch => 'upper_region' } )->as_hashref->all;
    my @objs;

    foreach my $obj (@list) {
        push @objs, {
            (
                (map { $_ => $obj->{$_} }
                  qw(
                  id
                  name
                  name_url
                  description
                  city_id
                  depth_level
                  created_by
                  created_at
                  automatic_fill),
                    ('polygon_path' => $obj->{polygon_path})x!! exists $c->req->params->{with_polygon_path}
                ),

                city => {
                    (
                        map { $_ => $c->stash->{city}->$_ }
                        qw(
                        name name_uri uf pais
                        )
                    ),
                },
                upper_region => $obj->{upper_region}
                ? {
                    id       => $obj->{upper_region}{id},
                    name     => $obj->{upper_region}{name},
                    name_url => $obj->{upper_region}{name_url},
                }
                : undef
            ),
            url => $c->uri_for_action( $self->action_for('region'), [ $c->stash->{city}->id, $obj->{id} ] )->as_string,

        };
    }

    $self->status_ok( $c, entity => { regions => \@objs } );
}
with 'Iota::TraitFor::Controller::Search';
1;

