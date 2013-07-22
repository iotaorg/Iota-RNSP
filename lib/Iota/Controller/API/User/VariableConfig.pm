package Iota::Controller::API::User::VariableConfig;

use Moose;
use JSON qw (encode_json);
BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/user/object') : PathPart('variable_config') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{user}       = $c->stash->{object}->next;
    $c->stash->{collection} = $c->stash->{user}->user_variable_configs;

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $self->status_bad_request( $c, message => 'invalid.argument' ), $c->detach
      unless $id =~ /^[0-9]+$/;

    $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
    $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub variable_config : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

=pod

=encoding utf-8

informacoes sobre um preenchimento especifico de um indicador sobre um periodo.

GET /api/user/$id/variable_config/$id

Retorna:

{
    display_in_home :  "XXXXXX",
    variable_id          :  35,
}


=cut

sub variable_config_GET {
    my ( $self, $c ) = @_;
    my $object_ref = $c->stash->{object}->as_hashref->next;

    $self->status_ok( $c, entity => { ( map { $_ => $object_ref->{$_} } qw(display_in_home variable_id) ) } );
}

=pod

atualizar variavel

POST /api/user/$id/variable_config/$id

Retorna:

    user.variable_config.update.display_in_home

=cut

sub variable_config_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));

    my $obj_rs = $c->stash->{object}->next;

    if ( $c->user->id != $obj_rs->user_id && !$c->check_any_user_role(qw(admin superadmin)) ) {
        $self->status_forbidden( $c, message => "access denied", ), $c->detach;
    }

    my $param = $c->req->params->{user}{variable_config}{update};
    $param->{id} = $obj_rs->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $obj = $dm->get_outcome_for('user.variable_config.update');

    $self->status_accepted(
        $c,
        location => $c->uri_for( $self->action_for('variable_config'), [ $c->stash->{user}->id, $obj->id ] )->as_string,
        entity => { id => $obj->id }
      ),

      $c->detach;
}

=pod

Apaga o registro da tabela UserVariableConfig

DELETE /api/user/$id/variable_config/$id

Retorna: No-content ou Gone

=cut

sub variable_config_DELETE {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));

    my $obj = $c->stash->{object}->next;
    $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

    if ( $c->user->id == $obj->user_id || $c->check_any_user_role(qw(admin superadmin)) ) {
        $obj->delete;
    }

    $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}

=pod

define o valor para a variavel para o usuario logado

POST /api/user/$id/variable_config

Param:

    user.variable_config.create.display_in_home
    user.variable_config.create.variable_id


Retorna:

    {"id":3}

=cut

sub list_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));

    my $param = $c->req->params->{user}{variable_config}{create};
    $param->{user_id} = $c->stash->{user}->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $object = $dm->get_outcome_for('user.variable_config.create');

    $self->status_created(
        $c,
        location =>
          $c->uri_for( $self->action_for('variable_config'), [ $c->stash->{user}->id, $object->id ] )->as_string,
        entity => { id => $object->id }
    );

}

sub list_GET {
    my ( $self, $c ) = @_;

    if ( exists $c->req->params->{variable_id} ) {
        my $config = $c->stash->{collection}->search_rs(
            {
                variable_id => $c->req->params->{variable_id},
                user_id     => $c->stash->{user}->id
            }
        )->as_hashref->next;

        $c->detach('/error_404') unless $config;

        $self->status_ok( $c, entity => { ( map { $_ => $config->{$_} } qw(id display_in_home variable_id) ) } );
    }
    else {

        my $configrs = $c->stash->{collection}->search_rs( { user_id => $c->stash->{user}->id } )->as_hashref;

        my $out = {};
        while ( my $r = $configrs->next ) {
            $out->{ $r->{variable_id} } = { ( map { $_ => $r->{$_} } qw(id display_in_home) ) };
        }
        $self->status_ok( $c, entity => $out );
    }
}

1;

