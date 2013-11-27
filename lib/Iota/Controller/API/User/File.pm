package Iota::Controller::API::User::File;

use Moose;
use JSON qw (encode_json);
BEGIN { extends 'Catalyst::Controller::REST' }
use Path::Class qw(dir);

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/user/object') : PathPart('file') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{user}       = $c->stash->{object}->next;
    $c->stash->{collection} = $c->stash->{user}->user_files;

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $self->status_bad_request( $c, message => 'invalid.argument' ), $c->detach
      unless $id =~ /^[0-9]+$/;

    $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
    $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub file : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

sub file_GET {
    my ( $self, $c ) = @_;
    my $object_ref = $c->stash->{object}->as_hashref->next;

    $self->status_ok(
        $c,
        entity => {
            (
                map { $_ => $object_ref->{$_} }
                  qw(
                  id
                  created_at
                  description
                  public_name
                  hide_listing
                  class_name
                  public_url
                  private_path
                  )
            )
        }
    );
}

sub file_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));

    my $obj_rs = $c->stash->{object}->next;

    if ( $c->user->id != $obj_rs->user_id && !$c->check_any_user_role(qw(admin superadmin)) ) {
        $self->status_forbidden( $c, message => "access denied", ), $c->detach;
    }

    my $param = $c->req->params->{user}{file}{update};
    $param->{id} = $obj_rs->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $obj = $dm->get_outcome_for('user.file.update');

    $self->status_accepted(
        $c,
        location => $c->uri_for( $self->action_for('file'), [ $c->stash->{user}->id, $obj->id ] )->as_string,
        entity => { id => $obj->id }
      ),

      $c->detach;
}

sub file_DELETE {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));

    my $obj = $c->stash->{object}->next;
    $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

    if ( $c->user->id == $obj->user_id || $c->check_any_user_role(qw(admin superadmin)) ) {
        unlink( $obj->private_path );
        $obj->delete;
    }

    $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}

sub list_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));

    my $param = $c->req->params->{user}{file}{create};
    $param->{user_id} = $c->stash->{user}->id;

    my $classe = $param->{class_name};

    $c->res->content_type('application/json; charset=utf8');

    my $upload = $c->req->upload('arquivo');
    if ($upload) {
        my $user_id = $c->stash->{user}->id;
        my $t       = new Text2URI();
        my $filename =
          sprintf( 'user_%i_%s_%s', $user_id, $classe, substr( $t->translate( $upload->basename ), 0, 200 ) );

        my $private_path =
          $c->config->{private_path} =~ /^\//o
          ? dir( $c->config->{private_path} )->resolve . '/' . $filename
          : Iota->path_to( $c->config->{private_path}, $filename );

        $self->status_bad_request( $c, message => "Copy failed: $!" ), $c->detach
          unless ( $upload->copy_to($private_path) );

        chmod 0644, $private_path;

        my $public_url = $c->uri_for( $c->config->{public_url} . '/' . $filename )->as_string;

        $param->{private_path} = "$private_path";
        $param->{public_url}   = $public_url;

        $param->{hide_listing} = 0 unless exists $param->{hide_listing};

    }
    else {
        $self->status_bad_request( $c, message => 'no upload found' ), $c->detach;
    }

    my $dm = $c->model('DataManager');
    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $object = $dm->get_outcome_for('user.file.create');

    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('file'), [ $c->stash->{user}->id, $object->id ] )->as_string,
        entity => { id => $object->id }
    );

}

sub list_GET {
    my ( $self, $c ) = @_;

    my $query = $c->stash->{collection}->as_hashref;

    $c->stash->{collection} = $c->stash->{collection}->search({
        hide_listing => $c->req->params->{hide_listing} ? 1 : 0
    }) if exists $c->req->params->{hide_listing} ;

    my $out = {};
    while ( my $r = $query->next ) {
        push @{ $out->{files} }, {
            (
                map { $_ => $r->{$_} }
                  qw(
                  id
                  created_at
                  description
                  public_name
                  hide_listing
                  class_name
                  public_url
                  private_path
                  )
            )
        };
    }
    $self->status_ok( $c, entity => $out );

}
with 'Iota::TraitFor::Controller::Search';

1;

