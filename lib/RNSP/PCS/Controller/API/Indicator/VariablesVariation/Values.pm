package RNSP::PCS::Controller::API::Indicator::VariablesVariation::Values;

use Moose;
use RNSP::IndicatorFormula;
use JSON qw (encode_json);
BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/indicator/variablesvariation/object') : PathPart('values') : CaptureArgs(0) {
   my ( $self, $c ) = @_;

   $c->stash->{variables_variation} = $c->stash->{object}->next;
   $c->stash->{collection} = $c->stash->{variables_variation}->indicator_variables_variations_values;

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
   my ( $self, $c, $id ) = @_;
   $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );
   $c->stash->{object}->count > 0 or $c->detach('/error_404') unless $c->req->method eq 'DELETE';
}

sub values : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
  my ( $self, $c ) = @_;

}

=pod

=encoding utf-8



=cut

sub values_GET {
   my ( $self, $c ) = @_;
   my $object_ref  = $c->stash->{object}->as_hashref->next;

   $self->status_ok(
      $c,
      entity => {
         (map { $_ => $object_ref->{$_} } qw(
         id
         indicator_variation_id
         indicator_variables_variation_id
         value
         value_of_date
         valid_from
         user_id
         created_at
         ))
      }
   );
}

=pod


=cut

sub values_POST {
   my ( $self, $c ) = @_;

   $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin user));

   my $obj_rs = $c->stash->{object}->next;

   if ( $c->user->id != $obj_rs->user_id || !$c->check_any_user_role(qw(admin))){
      $self->status_forbidden( $c, message => "access denied", ), $c->detach;
   }

   my $param = $c->req->params->{indicator}{variation_value}{update};

   $param->{indicator_variation_id} = $c->stash->{variables_variation}->id;
   $param->{indicator_id}           = $c->stash->{indicator}->id;
   $param->{user_id}                = $c->user->id;

   my $f =  RNSP::IndicatorFormula->new(
      formula => $c->stash->{indicator}->formula,
      schema  => $c->model('DB')->schema
   );
   my ($any_var) = $f->variables;
   $param->{period} = $any_var ? eval{$c->model('DB')->resultset('Variable')->find($any_var)->period} : '';

   $param->{id} = $obj_rs->id;

   my $dm = $c->model('DataManager');

   $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

   my $obj = $dm->get_outcome_for('indicator.variation_value.update');
   $self->status_accepted(
      $c,
         location => $c->uri_for( $self->action_for('values'), [ $c->stash->{indicator}->id, $param->{indicator_variation_id}, $obj->id ] )->as_string,
         entity => { id => $obj->id }
   ),

   $c->detach;
}


=pod

   Apaga o registro da tabela indicator_valuess


=cut

sub values_DELETE {
   my ( $self, $c ) = @_;

   $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin user));

   my $obj = $c->stash->{object}->next;
   $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

   if ($c->user->id == $obj->user_id || $c->check_any_user_role(qw(admin))){
      $c->logx('Apagou informação de indicator_valuess ' . $obj->id);
      $obj->delete;
   }

   $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}

sub list_GET {
   my ( $self, $c ) = @_;

   my $valid_from = ($c->req->params->{valid_from}||'') =~ /^\d{4}-\d{2}-\d{2}$/ ?
      $c->req->params->{valid_from} : undef;

   my @list = $c->stash->{collection}->search({
      ($valid_from ? ( valid_from => $valid_from) : ())
   })->as_hashref->all;
   my @objs;

   foreach my $obj (@list){
      push @objs, {

         (map { $_ => $obj->{$_} } qw(
         id
         indicator_variation_id
         indicator_variables_variation_id
         value
         value_of_date
         valid_from
         user_id
         created_at)),
         url => $c->uri_for_action( $self->action_for('values'), [
            $c->stash->{indicator}->id,
            $c->stash->{variables_variation}->id,
            $obj->{id} ] )->as_string,

      }
   }

   $self->status_ok( $c,
      entity => {
         values => \@objs
      }
   );
}


=pod

POST /api/indicator/$id/values

Param:

      indicator.variation_value.create:
         value*
         value_of_date*
         indicator_variation_id*

Retorna:

    {"id":3}

=cut

sub list_POST {
   my ( $self, $c ) = @_;

   $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin user));

   my $param = $c->req->params->{indicator}{variation_value}{create};

   $param->{indicator_variables_variation_id} = $c->stash->{variables_variation}->id;
   $param->{indicator_id}           = $c->stash->{indicator}->id;
   $param->{user_id}                = $c->user->id;

   my $f =  RNSP::IndicatorFormula->new(
      formula => $c->stash->{indicator}->formula,
      schema  => $c->model('DB')->schema
   );
   my ($any_var) = $f->variables;
   $param->{period} = $any_var ? eval{$c->model('DB')->resultset('Variable')->find($any_var)->period} : '';

   my $dm = $c->model('DataManager');
   $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

   my $object = $dm->get_outcome_for('indicator.variation_value.create');
   $self->status_created(
      $c,
      location => $c->uri_for( $self->action_for('values'), [ $c->stash->{indicator}->id, $param->{indicator_variables_variation_id}, $object->id ] )->as_string,
      entity => {
         id   => $object->id,
         valid_from => $object->valid_from->ymd,
      }
   );
}



1;

