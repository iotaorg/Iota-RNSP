package RNSP::PCS::Controller::API::Indicator::Variations;

use Moose;
use JSON qw (encode_json);
BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/indicator/object') : PathPart('variation') : CaptureArgs(0) {
   my ( $self, $c ) = @_;

   $c->stash->{indicator} = $c->stash->{object}->next;
   $c->stash->{collection} = $c->stash->{indicator}->indicator_variations;

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
   my ( $self, $c, $id ) = @_;
   $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
   $c->stash->{object}->count > 0 or $c->detach('/error_404') unless $c->req->method eq 'DELETE';
}

sub variation : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
  my ( $self, $c ) = @_;

}

=pod

=encoding utf-8



=cut

sub variation_GET {
   my ( $self, $c ) = @_;
   my $object_ref  = $c->stash->{object}->as_hashref->next;

   $self->status_ok(
      $c,
      entity => {
         (map { $_ => $object_ref->{$_} } qw(indicator_id name order))
      }
   );
}

=pod

   atualizar variavel

   POST /api/indicator/$id/variation/$id

      indicator.variation.update:
         name *

=cut

sub variation_POST {
   my ( $self, $c ) = @_;

   $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin user));

   my $obj_rs = $c->stash->{object}->next;

   if ( $c->user->id != $c->stash->{indicator}->user_id || !$c->check_any_user_role(qw(admin))){
      $self->status_forbidden( $c, message => "access denied", ), $c->detach;
   }

      my $param = $c->req->params->{indicator}{variation}{update};
   $param->{id} = $obj_rs->id;


   my $dm = $c->model('DataManager');

   $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

   my $obj = $dm->get_outcome_for('indicator.variation.update');
   $self->status_accepted(
      $c,
         location => $c->uri_for( $self->action_for('variation'), [ $c->stash->{indicator}->id, $obj->id ] )->as_string,
         entity => { id => $obj->id }
   ),

   $c->detach;
}


=pod

   Apaga o registro da tabela indicator_variations

   DELETE /api/indicator/$id/variation/$id

   Retorna: No-content ou Gone

=cut

sub variation_DELETE {
   my ( $self, $c ) = @_;

   $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin user));

   my $obj = $c->stash->{object}->next;
   $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

   if ($c->user->id == $obj->indicator_id || $c->check_any_user_role(qw(admin))){
      $c->logx('Apagou informação de indicator_variations ' . $obj->id);

      $c->model('DB::IndicatorVariablesVariationsValue')->search({
         indicator_variation_id => $obj->id
      })->delete;

      $obj->delete;
   }

   $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}

sub list_GET {
   my ( $self, $c ) = @_;

   my @list = $c->stash->{collection}->search(undef, {order_by=>'order'})->as_hashref->all;
   my @objs;

   foreach my $obj (@list){
      push @objs, {

         (map { $_ => $obj->{$_} } qw(
         id indicator_id name order
         created_at)),
         url => $c->uri_for_action( $self->action_for('variation'), [ $c->stash->{indicator}->id, $obj->{id} ] )->as_string,
      }
   }

   $self->status_ok( $c,
      entity => {
         variations => \@objs
      }
   );
}


=pod

POST /api/indicator/$id/variation

Param:

      indicator.variation.create:
         name

Retorna:

    {"id":3}

=cut

sub list_POST {
    my ( $self, $c ) = @_;

    if ($c->stash->{indicator}->dynamic_variations) {
        $self->status_forbidden( $c, message => "access denied", ), $c->detach
            unless $c->check_any_user_role(qw(admin _movimento _prefeitura));
    }else{
        $self->status_forbidden( $c, message => "access denied", ), $c->detach
            unless $c->check_any_user_role(qw(admin user));
    }

   $c->req->params->{indicator}{variation}{create}{indicator_id} = $c->stash->{indicator}->id;
   $c->req->params->{indicator}{variation}{create}{user_id} = $c->user->id;


   my $dm = $c->model('DataManager');
   $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

   my $object = $dm->get_outcome_for('indicator.variation.create');

   $self->status_created(
      $c,
      location => $c->uri_for( $self->action_for('variation'), [ $c->stash->{indicator}->id, $object->id ] )->as_string,
      entity => {
      id   => $object->id
      }
   );

}



1;

