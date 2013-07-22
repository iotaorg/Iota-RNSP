package Iota::Controller::API::Indicator::VariablesVariation;

use Moose;
use JSON qw (encode_json);
BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/indicator/object') : PathPart('variables_variation') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{indicator}  = $c->stash->{object}->next;
    $c->stash->{collection} = $c->stash->{indicator}->indicator_variables_variations;

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $self->status_bad_request( $c, message => 'invalid.argument' ), $c->detach
      unless $id =~ /^[0-9]+$/;

    $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
    $c->stash->{object}->count > 0 or $c->detach('/error_404') unless $c->req->method eq 'DELETE';
}

sub variables_variation : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

=pod

=encoding utf-8

   name
   type
   explanation

=cut

sub variables_variation_GET {
    my ( $self, $c ) = @_;
    my $object_ref = $c->stash->{object}->as_hashref->next;

    $self->status_ok( $c, entity => { ( map { $_ => $object_ref->{$_} } qw(indicator_id name type explanation ) ) } );
}

=pod

   atualizar variavel

   POST /api/indicator/$id/variables_variation/$id

   Retorna:

      indicator.variables_variation.update:
         name *
         type
         explanation

=cut

sub variables_variation_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));

    my $obj_rs = $c->stash->{object}->next;

    if ( $c->user->id != $c->stash->{indicator}->user_id && !$c->check_any_user_role(qw(admin superadmin)) ) {
        $self->status_forbidden( $c, message => "access denied", ), $c->detach;
    }

    my $param = $c->req->params->{indicator}{variables_variation}{update};
    $param->{id} = $obj_rs->id;

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $obj = $dm->get_outcome_for('indicator.variables_variation.update');
    $self->status_accepted(
        $c,
        location =>
          $c->uri_for( $self->action_for('variables_variation'), [ $c->stash->{indicator}->id, $obj->id ] )->as_string,
        entity => { id => $obj->id }
      ),

      $c->detach;
}

=pod

   Apaga o registro da tabela indicator_variables_variations

   DELETE /api/indicator/$id/variables_variation/$id

   Retorna: No-content ou Gone

=cut

sub variables_variation_DELETE {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));

    my $obj = $c->stash->{object}->next;
    $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

    if ( $c->user->id == $obj->indicator_id || $c->check_any_user_role(qw(admin superadmin)) ) {
        $c->logx( 'Apagou informação de indicator_variables_variations ' . $obj->id );

        $c->model('DB::IndicatorVariablesVariationsValue')->search( { indicator_variables_variation_id => $obj->id } )
          ->delete;

        $obj->delete;
    }

    $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}

sub list_GET {
    my ( $self, $c ) = @_;

    my @list = $c->stash->{collection}->as_hashref->all;
    my @objs;

    foreach my $obj (@list) {
        push @objs, {

            (
                map { $_ => $obj->{$_} }
                  qw(
                  id indicator_id name type explanation
                  created_at)
            ),
            url => $c->uri_for_action(
                $self->action_for('variables_variation'), [ $c->stash->{indicator}->id, $obj->{id} ]
              )->as_string,

        };
    }

    $self->status_ok( $c, entity => { variables_variations => \@objs } );
}

=pod

POST /api/indicator/$id/variables_variation

Param:

      indicator.variables_variation.create:
         name *
         type
         explanation

Retorna:

    {"id":3}

=cut

sub list_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));

    $c->req->params->{indicator}{variables_variation}{create}{indicator_id} = $c->stash->{indicator}->id;

    my $dm = $c->model('DataManager');
    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $object = $dm->get_outcome_for('indicator.variables_variation.create');

    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('variables_variation'), [ $c->stash->{indicator}->id, $object->id ] )
          ->as_string,
        entity => { id => $object->id }
    );

}

1;

