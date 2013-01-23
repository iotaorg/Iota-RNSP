
package RNSP::PCS::Controller::API::Indicator;

use Moose;
use JSON qw(encode_json);
use RNSP::IndicatorFormula;

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/base') : PathPart('indicator') : CaptureArgs(0) {
  my ( $self, $c ) = @_;
  $c->stash->{collection} = $c->model('DB::Indicator');

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
  my ( $self, $c, $id ) = @_;
  $c->stash->{object} = $c->stash->{collection}->search_rs( { 'me.id' => $id } );

  my %roles = map { $_ => 1 } $c->user->roles;

  my @roles;
  push @roles, {indicator_roles => {like => '%_prefeitura%'} } if $roles{admin} || $roles{_prefeitura};
  push @roles, {indicator_roles => {like => '%_movimento%'}  } if $roles{admin} || $roles{_movimento};

  $c->stash->{object} = $c->stash->{object}->search({ '-or' => \@roles });


  $c->stash->{object}->count > 0 or $c->detach('/error_404');
}


sub all_variable : Chained('base') : PathPart('variable') : Args(0) : ActionClass('REST') {
  my ( $self, $c ) = @_;

}
=pod

retorna
\ {
    variables:  [
        [0] {
            id          :  337,
            indicator_id:  332,
            name        :  "Pessoas"
        },
        [1] {
            id          :  338,
            indicator_id:  332,
            name        :  "variavel para teste"
        }
    ]
}

=cut

sub all_variable_GET {
   my ( $self, $c ) = @_;

    my @list = $c->model('DB::IndicatorVariablesVariation')->as_hashref->all;
    my @objs;

    foreach my $obj (@list){
        push @objs, {
            (map { $_ => $obj->{$_} } qw(
               id name indicator_id
            ))
        }
    }

    $self->status_ok(
        $c,
        entity => {
        variables => \@objs
        }
    );
}

sub indicator : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
  my ( $self, $c ) = @_;

}

=pod

=encoding utf-8

detalhe da variavel

GET /api/indicator/$id

Retorna:

    {
        "source": "me",
        "name": "Foo Bar",
        "axis_id": "2",
        "goal_operator": ">=",
        "tags": "you,me,she",
        "chart_name": "pie",
        "goal": "33",
        "created_at": "2012-09-28 03:25:01.706615",
        "formula": "$A + $B",
        "explanation": "explanation",
        "goal_source": "@fulano",
        "created_by": {
            "name": "admin",
            "id": 1
        }
    }

=cut

sub indicator_GET {
   my ( $self, $c ) = @_;

   my $object_ref  = $c->stash->{object}->search(undef, {prefetch => ['owner','axis']})->next;

   my $f = new RNSP::IndicatorFormula(
      formula => $object_ref->formula,
      schema => $c->model('DB')->schema);
   my ($any_var) = $f->variables;

   my $ret = {

      $object_ref->indicator_type eq 'varied' && ! $object_ref->dynamic_variations ? (variations => [
         map { { id => $_->id, name => $_->name } } $object_ref->indicator_variations->search(undef,{order_by => 'order'})->all
      ]) : (),

      $object_ref->indicator_type eq 'varied' ? (variables => [
         map { { id => $_->id, name => $_->name } } $object_ref->indicator_variables_variations
      ]) : (),

      period     => $any_var ? eval{$c->model('DB')->resultset('Variable')->find($any_var)->period} : undef,
      created_by => {
        map { $_ => $object_ref->owner->$_ } qw(name id)
      },
      axis => {
        map { $_ => $object_ref->axis->$_ } qw(name id)
      },

      (map { $_ => $object_ref->$_ } qw(name goal axis_id formula source explanation observations
            goal_source tags goal_operator chart_name goal_explanation sort_direction name_url
               indicator_roles variety_name indicator_type summarization_method all_variations_variables_are_required
               dynamic_variations
        ))
    };
    $ret->{created_at} = $object_ref->created_at->datetime;

  $self->status_ok(
    $c,
    entity => $ret
  );

}

=pod

atualizar variavel

POST /api/indicator/$id

Retorna:

    indicator.update.name         Texto: Nome
    indicator.update.formula      Texto: formula das variaveis
    indicator.update.goal         Texto: numero que se quer chegar
    indicator.update.axis_id         Texto: (talvez seja a categoria)
    indicator.update.explanation         Texto: explicacao
    indicator.update.source              Texto: fonte do indicador
    indicator.update.goal_source         Texto: fonte da meta

    indicator.update.tags             Texto: tags separadas por virgulas
    indicator.update.goal_operator    Texto: '>=', '=', '<='
    indicator.update.chart_name       Texto: 'pie', 'bar', ta livre, mas salve com um padrao em ingles
    indicator.update.goal_explanation Texto: explicacao da meta
    indicator.update.sort_direction   Texto: 'greater value','greater rating','lowest value','lowest rating'


=cut

sub indicator_POST {
  my ( $self, $c ) = @_;
    $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->check_user_roles(qw(admin));


  $c->req->params->{indicator}{update}{id} = $c->stash->{object}->next->id;

  my $dm = $c->model('DataManager');

  $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
    unless $dm->success;

  my $obj = $dm->get_outcome_for('indicator.update');

  $c->logx('Atualizou indicador' . $obj->name, indicator_id => $obj->id);

  $self->status_accepted(
    $c,
    location =>
      $c->uri_for( $self->action_for('indicator'), [ $obj->id ] )->as_string,
        entity => { name => $obj->name, id => $obj->id }
    ),
    $c->detach
    if $obj;
}


=pod

apagar variavel

DELETE /api/indicator/$id

Retorna: No-content ou Gone

=cut

sub indicator_DELETE {
   my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->check_user_roles(qw(admin));


   my $obj = $c->stash->{object}->next;
   $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

   $c->model('DB::IndicatorVariablesVariationsValue')->search({
      indicator_variables_variation_id => [map {$_->id} $obj->indicator_variables_variations->all ]
   })->delete;

   $obj->indicator_variations->delete;

   $obj->indicator_variables_variations->delete;

   $obj->user_indicators->delete;
   $obj->delete;

   $self->status_no_content($c);
}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}


=pod

listar variaveis

GET /api/indicator

Retorna:

    {
        "users": [
            {
                "id":1,
                "source": "me",
                "name": "Foo Bar",
                "axis_id": "Y",
                "goal_operator": ">=",
                "tags": "you,me,she",
                "chart_name": "pie",
                "goal": "33",
                "created_at": "2012-09-28 03:25:01.706615",
                "formula": "$A + $B",
                "explanation": "explanation",
                "goal_source": "@fulano",
                "created_by": {
                    "name": "admin",
                    "id": 1
                }
            }
            ...
        ]
    }

=cut

sub list_GET {
  my ( $self, $c ) = @_;

    my $rs = $c->stash->{collection}->search_rs( undef, { prefetch => ['owner','axis'] } );

    my %roles = map { $_ => 1 } $c->user->roles;

    my @roles;
    push @roles, {indicator_roles => {like => '%_prefeitura%'} } if $roles{admin} || $roles{_prefeitura};
    push @roles, {indicator_roles => {like => '%_movimento%'}  } if $roles{admin} || $roles{_movimento};

    $rs = $rs->search({ '-or' => \@roles });

    my @list = $rs->as_hashref->all;
    my @objs;

    foreach my $obj (@list){
        push @objs, {


            created_by => {
                map { $_ => $obj->{owner}{$_} } qw(name id)
            },
            axis => {
                map { $_ => $obj->{axis}{$_} } qw(name id)
            },

            (map { $_ => $obj->{$_} } qw(id name goal axis_id formula source explanation observations
                 goal_source tags goal_operator chart_name goal_explanation sort_direction name_url
                 indicator_roles variety_name indicator_type summarization_method all_variations_variables_are_required
                 dynamic_variations

            created_at)),
            url => $c->uri_for_action( $self->action_for('indicator'), [ $obj->{id} ] )->as_string,

        }
    }

    $self->status_ok(
        $c,
        entity => {
        indicators => \@objs
        }
    );
}


=pod

criar variavel

POST /api/indicator

Param:

    indicator.create.name        Texto, Requerido: Nome
    indicator.create.formula     Texto, Requerido: formula das variaveis
    indicator.create.goal        Texto, Requerido: numero que se quer chegar
    indicator.create.axis_id        Texto, Requerido: (talvez seja a categoria)

    indicator.create.explanation         Texto: explicacao
    indicator.create.source              Texto: fonte do indicador
    indicator.create.goal_source         Texto: fonte da meta
    indicator.create.tags             Texto: tags separadas por virgulas
    indicator.create.goal_operator    Texto: '>=', '=', '<='
    indicator.create.chart_name       Texto: 'pie', 'bar', ta livre, mas salve com um padrao em ingles

    indicator.create.goal_explanation Texto: explicacao da meta
    indicator.create.sort_direction   Texto: 'greater value','greater rating','lowest value','lowest rating'


Retorna:

    {"name":"Foo Bar","id":3}


=cut

sub list_POST {
  my ( $self, $c ) = @_;
  $self->status_forbidden( $c, message => "access denied", ), $c->detach
    unless $c->check_user_roles(qw(admin));


  $c->req->params->{indicator}{create}{user_id} = $c->user->id;

  my $dm = $c->model('DataManager');

  $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
    unless $dm->success;
  my $object = $dm->get_outcome_for('indicator.create');
  $c->logx('Adicionou indicador' . $object->name, indicator_id => $object->id);

  $self->status_created(
    $c,
    location => $c->uri_for( $self->action_for('indicator'), [ $object->id ] )->as_string,
    entity => {
      name => $object->name,

      name_url => $object->name_url,
      id   => $object->id,

    }
  );

}

with 'RNSP::PCS::TraitFor::Controller::Search';
1;

