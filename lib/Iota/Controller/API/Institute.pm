
package Iota::Controller::API::Institute;

use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/base') : PathPart('institute') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{collection} = $c->model('DB::Institute');

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
        $self->status_bad_request( $c, message => 'invalid.argument' ), $c->detach
      unless $id =~ /^[0-9]+$/;

    $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );

    $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub institute : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

=pod

=encoding utf-8

detalhe da cidade

GET /api/institute/$id

Retorna:

    {
        "id": "1",
        "created_at": "2012-09-27 18:55:53.480272",
        "name": "Foo Bar"
    }

=cut

sub institute_GET {
    my ( $self, $c ) = @_;
    my $object_ref = $c->stash->{object}->as_hashref->next;

    $self->status_ok(
        $c,
        entity => {
            (
                map { $_ => $object_ref->{$_} }
                  qw(
                  id name short_name description

                  users_can_edit_value
                  users_can_edit_groups
                  can_use_custom_css
                  can_use_custom_pages

                  created_at
                  created_by

                  institute_id domain_name
                  )
            )
        }
    );
}

=pod

atualizar cidade

POST /api/institute/$id

Retorna:

    institute.update.name      Texto

=cut

sub institute_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(superadmin));

    $c->req->params->{institute}{update}{id} = $c->stash->{object}->next->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $obj = $dm->get_outcome_for('institute.update');

    $self->status_accepted(
        $c,
        location => $c->uri_for( $self->action_for('institute'), [ $obj->id ] )->as_string,
        entity => { name => $obj->name, id => $obj->id }
      ),
      $c->detach
      if $obj;
}

=pod

apagar cidade

DELETE /api/institute/$id

Retorna: No-content ou Gone

=cut

sub institute_DELETE {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(superadmin));

    my $obj = $c->stash->{object}->next;
    $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

    $obj->delete;

    $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}

=pod

listar cidades

GET /api/institute

Retorna:

    {
        "institutes": [
            {
                "name": "Foo Bar",
            }
        ]
    }

=cut

sub list_GET {
    my ( $self, $c ) = @_;

    my @list = $c->stash->{collection}->as_hashref->all;
    my @objs;

    foreach my $obj (@list) {
        push @objs, {
            (
                map { $_ => $obj->{$_} }
                  qw(
                  id name short_name description

                  users_can_edit_value
                  users_can_edit_groups
                  can_use_custom_css
                  can_use_custom_pages

                  created_at
                  created_by

                  institute_id domain_name
                  )
            ),
            url => $c->uri_for_action( $self->action_for('institute'), [ $obj->{id} ] )->as_string,
        };
    }

    $self->status_ok( $c, entity => { institute => \@objs } );
}

=pod

criar cidade

POST /api/institute

Param:

    institute.create.name      Texto, Requerido: nome da cidade

Retorna:

    {"name":"Foo Bar","id":3}

=cut

sub list_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(superadmin));

    $c->req->params->{institute}{create}{created_by} = $c->user->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;
    my $object = $dm->get_outcome_for('institute.create');

    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('institute'), [ $object->id ] )->as_string,
        entity => {
            name => $object->name,
            id   => $object->id,
        }
    );

}

sub stats : Chained('object') : PathPart('stats') : Args(0) : ActionClass('REST') {
}

sub stats_GET {
    my ( $self, $c ) = @_;

    my @rows = $c->model('DB::ViewInstituteStats')->search(
        undef,
        {
            bind         => [ $c->stash->{object}->next->id ],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    )->all;

    $self->status_ok( $c, entity => { stats => \@rows } );
}

with 'Iota::TraitFor::Controller::Search';
1;

