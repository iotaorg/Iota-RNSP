package Iota::PCS::Controller::API::User::IndicatorConfig;

use Moose;
use JSON qw (encode_json);
BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/user/object') : PathPart('indicator_config') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{user} = $c->stash->{object}->next;
    $c->stash->{collection} = $c->stash->{user}->user_indicator_configs;

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
  my ( $self, $c, $id ) = @_;
  $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
  $c->stash->{object}->count > 0 or $c->detach('/error_404');
}

sub indicator_config : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
  my ( $self, $c ) = @_;

}

=pod

=encoding utf-8

informacoes sobre um preenchimento especifico de um indicador sobre um periodo.

GET /api/user/$id/indicator_config/$id

Retorna:

{
    technical_information :  "XXXXXX",
    indicator_id          :  35,
}


=cut

sub indicator_config_GET {
    my ( $self, $c ) = @_;
    my $object_ref  = $c->stash->{object}->as_hashref->next;

    $self->status_ok(
        $c,
        entity => {
            (map { $_ => $object_ref->{$_} } qw(technical_information indicator_id))
        }
    );
}

=pod

atualizar variavel

POST /api/user/$id/indicator_config/$id

Retorna:

    user.indicator_config.update.technical_information

=cut

sub indicator_config_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
        unless $c->check_any_user_role(qw(admin user));

    my $obj_rs = $c->stash->{object}->next;

    if ( $c->user->id != $obj_rs->user_id || !$c->check_any_user_role(qw(admin))){
        $self->status_forbidden( $c, message => "access denied", ), $c->detach;
    }

    my $param = $c->req->params->{user}{indicator_config}{update};
    $param->{id} = $obj_rs->id;


    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
        unless $dm->success;

    my $obj = $dm->get_outcome_for('user.indicator_config.update');

    $self->status_accepted(
        $c,
            location => $c->uri_for( $self->action_for('indicator_config'), [ $c->stash->{user}->id, $obj->id ] )->as_string,
            entity => { id => $obj->id }
        ),

        $c->detach;
}


=pod

Apaga o registro da tabela UserIndicatorConfig

DELETE /api/user/$id/indicator_config/$id

Retorna: No-content ou Gone

=cut

sub indicator_config_DELETE {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
        unless $c->check_any_user_role(qw(admin user));

    my $obj = $c->stash->{object}->next;
    $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

    if ($c->user->id == $obj->user_id || $c->check_any_user_role(qw(admin))){
        $obj->delete;
    }


    $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}


=pod

define o valor para a variavel para o usuario logado

POST /api/user/$id/indicator_config

Param:

    user.indicator_config.create.technical_information
    user.indicator_config.create.indicator_id


Retorna:

    {"id":3}

=cut

sub list_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
        unless $c->check_any_user_role(qw(admin user));

    my $param = $c->req->params->{user}{indicator_config}{create};
    $param->{user_id} = $c->stash->{user}->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
        unless $dm->success;

    my $object = $dm->get_outcome_for('user.indicator_config.create');


    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('indicator_config'), [ $c->stash->{user}->id, $object->id ] )->as_string,
        entity => {
            id   => $object->id
        }
    );

}



sub list_GET {
    my ( $self, $c ) = @_;

    my $config = $c->stash->{collection}->
        search_rs( {
            indicator_id  => $c->req->params->{indicator_id},
            user_id       => $c->stash->{user}->id
        } )->as_hashref->next;

    $c->detach('/error_404') unless $config;

    $self->status_ok(
        $c,
        entity => {
            (map { $_ => $config->{$_} } qw(id technical_information indicator_id))
        }
    );
}



1;

