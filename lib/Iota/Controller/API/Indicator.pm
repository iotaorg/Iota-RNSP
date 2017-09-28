
package Iota::Controller::API::Indicator;

use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/base') : PathPart('indicator') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{collection} = $c->model('DB::Indicator');

}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $self->status_bad_request( $c, message => 'invalid.argument' ), $c->detach
      unless $id =~ /^[0-9]+$/;

    $c->stash->{object} =
      $c->stash->{collection}->search_rs( { 'me.id' => $id } );

    my %roles = map { $_ => 1 } $c->user->roles;

    #my @roles;
    #push @roles, {indicator_roles => {like => '%_prefeitura%'} } if $roles{admin} || $roles{_prefeitura};
    #push @roles, {indicator_roles => {like => '%_movimento%'}  } if $roles{admin} || $roles{_movimento};

    $c->stash->{object} = $c->stash->{object}->search(undef);

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

    foreach my $obj (@list) {
        push @objs, {
            (
                map { $_ => $obj->{$_} }
                  qw(
                  id name indicator_id
                  )
            )
        };
    }

    $self->status_ok( $c, entity => { variables => \@objs } );
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

    my $object_ref = $c->stash->{object}->search(
        undef,
        {
            prefetch =>
              [ 'owner', 'axis', 'axis_dim1', 'axis_dim2', 'axis_dim3', 'axis_dim4', 'indicator_network_configs' ]
        }
    )->next;

    my $where =
      $object_ref->dynamic_variations
      ? { user_id => [ $object_ref->user_id, $c->stash->{user_id} || $c->user->id ] }
      : { user_id => $object_ref->user_id };

    my $ret = {

        $object_ref->indicator_type eq 'varied'
        ? (
            variations => [
                map { { id => $_->id, name => $_->name } }
                  $object_ref->indicator_variations->search( $where, { order_by => 'order' } )->all
            ]
          )
        : (),

        $object_ref->indicator_type eq 'varied'
        ? ( variables => [ map { { id => $_->id, name => $_->name } } $object_ref->indicator_variables_variations ] )
        : (),

        network_configs => [
            map { { unfolded_in_home => $_->unfolded_in_home, network_id => $_->network_id } }
              $object_ref->indicator_network_configs
        ],

        created_by => { map { $_ => $object_ref->owner->$_ } qw(name id) },
        axis       => { map { $_ => $object_ref->axis->$_ } qw(name id) },
        axis_dim1 => ($object_ref->axis_dim1_id ? { map { $_ => $object_ref->axis_dim1->$_ } qw(name id) } : undef),
        axis_dim2 => ($object_ref->axis_dim2_id ? { map { $_ => $object_ref->axis_dim2->$_ } qw(name id) } : undef),
        axis_dim3 => ($object_ref->axis_dim3_id ? { map { $_ => $object_ref->axis_dim3->$_ } qw(name id description) }
        : undef),
        axis_dim4 => ($object_ref->axis_dim4_id ? { map { $_ => $object_ref->axis_dim4->$_ } qw(name id description) }
        : undef),

        (
            map { $_ => $object_ref->$_ }
              qw(name goal axis_id formula source explanation observations
              goal_source tags goal_operator chart_name goal_explanation sort_direction name_url
              variety_name indicator_type summarization_method all_variations_variables_are_required
              dynamic_variations

              visibility_level
              visibility_user_id

              featured_in_home

              period
              variable_type

              formula_human

              )
        ),

        $object_ref->visibility_level eq 'restrict'
        ? ( restrict_to_users => [ map { $_->user_id } $object_ref->indicator_user_visibilities ] )
        : (),

        $object_ref->visibility_level eq 'network'
        ? ( restrict_to_networks => [ map { $_->network_id } $object_ref->indicator_network_visibilities ] )
        : (),

    };
    $ret->{created_at} = $object_ref->created_at->datetime;
    $c->stash->{indicator_ref} = $object_ref;

    if ( defined $c->req->params->{prefetch_city} && $c->req->params->{prefetch_city} =~ /^[0-9]+$/ ) {

        my $r = $c->model('DB::City')->search_rs( { 'id' => $c->req->params->{prefetch_city} } )->as_hashref->next;

        if ($r) {

            $ret->{_prefetch}->{cidade} = {
                name                        => $r->{name},
                uf                          => $r->{uf},
                pais                        => $r->{pais},
                latitude                    => $r->{latitude},
                longitude                   => $r->{longitude},
                telefone_prefeitura         => $r->{telefone_prefeitura},
                endereco_prefeitura         => $r->{endereco_prefeitura},
                bairro_prefeitura           => $r->{bairro_prefeitura},
                cep_prefeitura              => $r->{cep_prefeitura},
                nome_responsavel_prefeitura => $r->{nome_responsavel_prefeitura},
                email_prefeitura            => $r->{email_prefeitura},
            };
        }

    }

    if ( defined $c->req->params->{prefetch_institute_metadata} && $c->req->params->{prefetch_institute_metadata} ) {

        $ret->{_prefetch}{institute_metadata} = $c->stash->{institute_metadata};

    }

    if ( defined $c->req->params->{prefetch_region} && $c->req->params->{prefetch_region} =~ /^[0-9]+$/ ) {

        my $r = $c->model('DB::Region')->search_rs( { 'id' => $c->req->params->{prefetch_region} } )->as_hashref->next;

        if ($r) {

            $ret->{_prefetch}{region} = {
                name     => $r->{name},
                name_url => $r->{name_url}
            };
        }

    }

    if ( defined $c->req->params->{with_indicator_availability} && $c->req->params->{with_indicator_availability} ) {

        my $indicator_availability = $c->model('DB::ViewIndicatorAvailability')->search(
            {},
            {
                bind => [ ( $c->stash->{indicator_ref}->id ) x 5 ],
                result_class => 'DBIx::Class::ResultClass::HashRefInflator'
            }
        )->next;

        $ret->{indicator_availability} = $indicator_availability;

        $c->forward('/load_region_names');

        $ret->{_prefetch}{region_classification_name} = $c->stash->{region_classification_name};

    }

    $self->status_ok( $c, entity => $ret );

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
      unless $c->check_any_user_role(qw(admin user superadmin));

    my $xx = $c->stash->{object}->next;
    $c->req->params->{indicator}{update}{id} = $xx->id;

    my %roles = map { $_ => 1 } $c->user->roles;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      if exists $roles{user} && $xx->user_id != $c->user->id;

    if (   ( $c->req->params->{indicator}{update}{visibility_level} || '' ) eq 'private'
        && ( $c->req->params->{indicator}{update}{visibility_user_id} || '' ) eq ''
        && $c->check_any_user_role(qw(admin superadmin)) ) {
        $c->req->params->{indicator}{update}{visibility_user_id} = $c->user->id;
    }

    delete $c->req->params->{indicator}{update}{visibility_level}
      if exists $roles{user};

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;

    my $obj = $dm->get_outcome_for('indicator.update');

    $c->logx( 'Atualizou indicador' . $obj->name, indicator_id => $obj->id );

    $self->status_accepted(
        $c,
        location => $c->uri_for( $self->action_for('indicator'), [ $obj->id ] )->as_string,
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
      unless $c->check_any_user_role(qw(admin user superadmin));

    my $obj = $c->stash->{object}->next;
    $self->status_gone( $c, message => 'deleted' ), $c->detach unless $obj;

    $c->model('DB')->schema->txn_do(
        sub {

            $c->model('DB::IndicatorVariablesVariationsValue')->search(
                {
                    indicator_variables_variation_id => [ map { $_->id } $obj->indicator_variables_variations->all ]
                }
            )->delete;

            $obj->user_indicator_configs->delete;

            $obj->indicator_user_visibilities->delete;
            $obj->indicator_network_configs->delete;

            $obj->indicator_values->delete;

            $obj->indicator_variables->delete;

            $obj->indicator_variations->delete;

            $obj->indicator_variables_variations->delete;
            $obj->indicator_network_visibilities->delete;

            $obj->end_user_indicator_users->delete;
            $obj->end_user_indicators->delete;

            $obj->user_indicators->delete;
            $obj->delete;
        }
    );

    if ($@) {
        $self->status_bad_request( $c, message => "$@" ), $c->detach;
    }

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

    my $rs = $c->stash->{collection}->search_rs( undef, { prefetch => [ 'owner', 'axis' ] } );

    my %roles = map { $_ => 1 } $c->user->roles;

    $c->req->params->{use} ||= 'list';

    # superadmin visualiza todas
    if ( !exists $roles{superadmin} ) {
        my @user_ids = (
            $roles{user}
            ? ( $c->user->id )
            : ()
        );

        my @networks = $c->user->networks ? $c->user->networks->all : ();

        if ( $roles{admin} ) {

            # todos os indicadores que os usuarios da rede dele pode ver

            foreach my $net (@networks) {
                @user_ids = ( map { $_->user_id } $net->network_users );
            }

        }

        $rs = $rs->filter_visibilities(
            networks_ids => [ map { $_->id } @networks ],
            users_ids    => \@user_ids,
          )->search(
            {
                is_fake => 0
            }
          );
    }

    if ( $c->req->params->{use} eq 'edit' ) {

        # se o uso dessa lista for para editar, entao temos que verificar algumas coisas a mais!

        $rs = $rs->search(
            {
                'me.user_id' => $c->user->id
            }
        ) if exists $roles{user};
    }
    if ( $c->req->params->{network_id} ) {
        $rs = $rs->search(
            {
                'indicator_network_visibilities.network_id' => $c->req->params->{network_id}
            },
            { join => 'indicator_network_visibilities' }
        );
    }
    my @list = $rs->as_hashref->all;
    my @objs;
    foreach my $obj (@list) {
        $obj->{indicator_network_configs} = []
          unless exists $obj->{indicator_network_configs};
        push @objs, {

            created_by      => { map { $_ => $obj->{owner}{$_} } qw(name id) },
            axis            => { map { $_ => $obj->{axis}{$_} } qw(name id) },
            network_configs => [
                map { { unfolded_in_home => $_->{unfolded_in_home}, network_id => $_->{network_id} } }
                  @{ $obj->{indicator_network_configs} }
            ],

            (
                map { $_ => $obj->{$_} }
                  qw(id name goal axis_id formula source explanation observations
                  goal_source tags goal_operator chart_name goal_explanation sort_direction name_url
                  variety_name indicator_type summarization_method all_variations_variables_are_required
                  dynamic_variations

                  visibility_level
                  visibility_user_id
                  visibility_country_id

                  featured_in_home
                  created_at)
            ),
            url => $c->uri_for_action( $self->action_for('indicator'), [ $obj->{id} ] )->as_string,

        };
    }

    if ( $c->req->params->{config_user_id} ) {
        my $rs = $c->model('DB::UserIndicatorConfig')->search(
            {
                indicator_id => { 'in' => [ map { $_->{id} } @objs ] },
                user_id      => $c->req->params->{config_user_id}
            }
        )->as_hashref;

        my $out = {};
        while ( my $r = $rs->next ) {
            $out->{ delete $r->{indicator_id} } = $r;
        }
        $_->{user_indicator_config} = delete $out->{ $_->{id} } for (@objs);
    }

    $self->status_ok( $c, entity => { indicators => \@objs } );
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
      unless $c->check_any_user_role(qw(admin superadmin user));

    $c->req->params->{indicator}{create}{user_id} = $c->user->id;
    my %roles = map { $_ => 1 } $c->user->roles;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      if exists $roles{user}
      && ( $c->req->params->{indicator}{create}{visibility_level} || '' ) ne 'private';

    if (
        (
            ( $c->req->params->{indicator}{create}{visibility_level} || '' ) eq 'private'
            && ( $c->req->params->{indicator}{create}{visibility_user_id}
                || '' ) eq ''
            && $c->check_any_user_role(qw(admin superadmin))
        )
        || exists $roles{user}
      ) {
        $c->req->params->{indicator}{create}{visibility_user_id} = $c->user->id;
    }

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => encode_json( $dm->errors ) ), $c->detach
      unless $dm->success;
    my $object = $dm->get_outcome_for('indicator.create');
    $c->logx( 'Adicionou indicador' . $object->name, indicator_id => $object->id );

    $self->status_created(
        $c,
        location => $c->uri_for( $self->action_for('indicator'), [ $object->id ] )->as_string,
        entity => {
            name => $object->name,

            name_url => $object->name_url,
            id       => $object->id,

        }
    );

}

with 'Iota::TraitFor::Controller::Search';
1;
