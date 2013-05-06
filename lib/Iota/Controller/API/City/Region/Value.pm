
package Iota::Controller::API::City::Region::Value;

use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/city/region/object') : PathPart('value') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{region}     = $c->stash->{object}->next;
    $c->stash->{collection} = $c->stash->{region}->region_variable_values;
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
    $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub variable : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}



sub variable_GET {
    my ( $self, $c ) = @_;
    my $objectect_ref = $c->stash->{object}->search( undef, { prefetch => [ 'owner', 'variable' ] } )->as_hashref->next;

    $self->status_ok(
        $c,
        entity => {
            created_by => { map { $_ => $objectect_ref->{owner}{$_} } qw(name id) },
            ( map { $_ => $objectect_ref->{variable}{$_} } qw(name type cognomen) ),
            ( map { $_ => $objectect_ref->{$_} } qw(value created_at value_of_date observations source region_id) )
        }
    );
}



sub variable_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));

    my $object_rs = $c->stash->{object}->next;

    # removido: $c->user->id != $object_rs->owner->id
    if ( !$c->check_any_user_role(qw(admin superadmin user)) ) {
        $self->status_forbidden( $c, message => "access denied", ), $c->detach;
    }
    $c->req->params->{region}{variable}{value}{update}{id} = $object_rs->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $object = $dm->get_outcome_for('region.variable.value.update');

    $c->logx( 'Atualizou valor '
          . $object->value
          . ' para '
          . $object->valid_from
          . ' na variavel '
          . $object->variable_id
          . ' RegionValID '
          . $object->id );

    $self->status_accepted(
        $c,
        location =>
          $c->uri_for( $self->action_for('variable'), [ $c->stash->{city}->id, $c->stash->{region}->id, $object->id ] )
          ->as_string,
        entity => { id => $object->id }
      ),
      $c->detach
      if $object;
}



sub variable_DELETE {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));

    my $object = $c->stash->{object}->next;
    $self->status_gone( $c, message => 'deleted' ), $c->detach unless $object;

    if ( $c->user->id == $object->owner->id || $c->check_any_user_role(qw(admin superadmin)) ) {
        $object->delete;
    }

    $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}



sub list_GET {
    my ( $self, $c ) = @_;

    my $wheres = {};
    $wheres->{'me.valid_from'} = $c->req->params->{valid_from}
        if exists $c->req->params->{valid_from} && $c->req->params->{valid_from} =~ /^\d{4}-\d{2}-\d{2}$/;

    $wheres->{'me.variable_id'} = $c->req->params->{variable_id}
        if exists $c->req->params->{variable_id} && $c->req->params->{variable_id} =~ /^\d+$/;

    $wheres->{'me.file_id'} = $c->req->params->{file_id}
        if exists $c->req->params->{file_id} && $c->req->params->{file_id} =~ /^\d+$/;

    if ($c->check_any_user_role(qw(admin superadmin))){
        $wheres->{'me.user_id'} = $c->req->params->{user_id}
            if exists $c->req->params->{user_id} && $c->req->params->{user_id} =~ /^\d+$/;
    }else{
        $wheres->{'me.user_id'} = $c->user->id;
    }

    my $objectect_ref = $c->stash->{collection}->search( $wheres, {
        prefetch => [ 'owner', 'variable' ],
        order_by => ['me.created_at','me.id']
    } )->as_hashref;

    my @objs;

    while (my $obj = $objectect_ref->next) {
        push @objs, {
            created_by => { map { $_ => $obj->{owner}{$_} } qw(name id) },
            ( map { $_ => $obj->{variable}{$_} } qw(name type cognomen) ),
            ( map { $_ => $obj->{$_} } qw(id value created_at value_of_date observations source region_id) ),

            url => $c->uri_for_action( $self->action_for('variable'), [ $c->stash->{city}->id, $c->stash->{region}->id, $obj->{id} ] )->as_string,

        };
    }

    $self->status_ok(
        $c,
        entity => {
            values => \@objs
        }
    );
}


sub list_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));

    $c->req->params->{region}{variable}{value}{create}{region_id} = $c->stash->{region}->id;

    $c->req->params->{region}{variable}{value}{create}{user_id} = $c->user->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $objectect = $dm->get_outcome_for('region.variable.value.create');

    $c->logx( 'Adicionou valor '
          . ( $objectect->value || '' )
          . ' para '
          . $objectect->valid_from
          . ' na variavel '
          . $objectect->variable_id
          . ' RegionValID '
          . $objectect->id );

    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('variable'),
            [ $c->stash->{city}->id, $c->stash->{region}->id, $objectect->id ] )->as_string,
        entity => { id => $objectect->id }
    );

}


sub list_PUT {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));

    $c->req->params->{region}{variable}{value}{put}{region_id} = $c->stash->{region}->id;
    $c->req->params->{region}{variable}{value}{put}{user_id}   = $c->user->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $objectect = $dm->get_outcome_for('region.variable.value.put');

    $c->logx( 'Atualizou valor '
          . $objectect->value
          . ' para '
          . $objectect->valid_from
          . ' na variavel '
          . $objectect->variable_id
          . ' RegionValID '
          . $objectect->id );

    # retorna created, mas pode ser updated
    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('variable'),
            [ $c->stash->{city}->id, $c->stash->{region}->id, $objectect->id ] )->as_string,
        entity => {
            id          => $objectect->id,
            valid_from  => $objectect->valid_from->ymd,
            valid_until => $objectect->valid_until->ymd
        }
    );

}

1;

