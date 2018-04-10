package Iota::Controller::API::Indicator::NetworkConfig;

use Moose;
use JSON qw (encode_json);
BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/indicator/object') : PathPart('network_config') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{indicator}  = $c->stash->{object}->next;
    $c->stash->{collection} = $c->stash->{indicator}->indicator_network_configs;

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $self->status_bad_request( $c, message => 'invalid.argument' ), $c->detach
      unless $id =~ /^[0-9]+$/;

    $c->stash->{object_id} = $id;
}

sub network_config : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

=pod

=encoding utf-8


=cut

sub network_config_GET {
    my ( $self, $c ) = @_;

    my $object_ref = $c->stash->{collection}->search( { network_id => $c->stash->{object_id} } )->as_hashref->next;
    $object_ref or $c->detach('/error_404');

    $self->status_ok( $c, entity => { ( map { $_ => $object_ref->{$_} } qw(unfolded_in_home) ) } );
}

=pod

atualizar variavel

POST /api/indicator/$id/network_config/$id

    indicator.network_config.upsert:
        unfolded_in_home *

=cut

sub network_config_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin user superadmin));

    my $param = $c->req->params->{indicator}{network_config}{upsert};

    $param->{network_id}   = $c->stash->{object_id};
    $param->{indicator_id} = $c->stash->{indicator}->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $obj = $dm->get_outcome_for('indicator.network_config.upsert');
    $self->status_accepted(
        $c,
        location =>
          $c->uri_for( $self->action_for('network_config'), [ $obj->indicator_id, $obj->network_id ] )->as_string,
        entity => {
            network_id   => $obj->network_id,
            indicator_id => $obj->indicator_id,
        }
      ),

      $c->detach;
}

=pod

Apaga o registro da tabela indicator_network_configs

DELETE /api/indicator/$id/network_config/$id

Retorna: No-content ou Gone

=cut

sub network_config_DELETE {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin user superadmin));

    my $obj = $c->stash->{collection}->search( { network_id => $c->stash->{object_id} } )->next;

    $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

    $obj->delete;

    $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}

sub list_GET {
    my ( $self, $c ) = @_;

    my @list = $c->stash->{collection}->as_hashref->all;
    my @objs;

    foreach my $obj (@list) {
        push @objs,
          {
            ( map { $_ => $obj->{$_} } qw(indicator_id network_id unfolded_in_home) ),
            url =>
              $c->uri_for_action( $self->action_for('network_config'), [ $obj->{indicator_id}, $obj->{network_id} ] )
              ->as_string,
          };
    }

    $self->status_ok( $c, entity => { network_configs => \@objs } );
}

1;

