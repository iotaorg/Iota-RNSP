package Iota::Controller::API::User::CloneVariable;

use Moose;
use JSON qw (encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/user/object') : PathPart('clone_variable') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{user}       = $c->stash->{object}->next;
    $c->stash->{collection} = undef;

}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}

=pod

POST "/api/user/$mov/clone_variable",
    [
        'period1' => '2010-01-01',
        'variable:19_1' => '1',
        'variable:20_1' => '1',
        'institute_id' => 1
    ]

=cut

sub list_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(user));

    my $institute = $c->req->params->{institute_id};

    my $me = $c->model('DB::User')->find( $c->user->id );
    $self->status_bad_request( $c, message => 'You cannot clone from your own institute!' ), $c->detach
      if $institute == $me->institute_id;

    my $another_user = $c->model('DB::User')->find(
        {
            institute_id => $institute,
            city_id      => $me->city_id,
        }
    );

    $self->status_bad_request( $c, message => 'No user in your city for institute you informed!' ), $c->detach
      unless $another_user;

    my $periods   = {};
    my $variables = {};

    my %params = %{ $c->req->params };
    foreach my $name ( keys %params ) {
        $periods->{$1} = $params{$name}
          if ( $name =~ /^period([0-9]+)$/ );
    }

    foreach my $name ( keys %params ) {

        if ( $name =~ /^variable:([0-9]+)_([0-9]+)$/ ) {
            my $period = $periods->{$2};

            $self->status_bad_request( $c, message => 'period not found' ), $c->detach
              unless $period;

            $variables->{$1}{$period} = 1 if $params{$name};
        }
    }

    $self->status_bad_request( $c, message => 'no variables' ), $c->detach
      unless keys %$variables;

    # chega de validar!

    my $schema       = $c->model('DB');
    my $all_ok       = 0;
    my $per_variable = {};
    eval {
        $schema->txn_do(
            sub {

                for my $var_id ( keys %$variables ) {

                    my @dates = keys %{ $variables->{$var_id} };
                    my $ok = $schema->schema->clone_values( $me->id, $another_user->id, $var_id, \@dates );
                    $all_ok += $ok->{clone_values};
                    $per_variable->{$var_id} = $ok;
                }
            }
        );
    };

    $self->status_bad_request( $c, message => 'Error: ' . $@ ), $c->detach if $@;

    $self->status_ok(
        $c,
        entity => {
            message          => "successfully cloned",
            number_of_clones => $all_ok,
            clones           => $per_variable
        }
    );

}

sub list_GET {
    my ( $self, $c ) = @_;

    my @variables = grep { $_ =~ /^[0-9]+$/ } split /,/, $c->req->params->{variables};
    $self->status_bad_request( $c, message => 'no variable found.' ), $c->detach unless @variables;

    my $institute = $c->req->params->{institute_id};

    my $me = $c->model('DB::User')->find( $c->user->id );
    $self->status_bad_request( $c, message => 'You cannot clone from your own institute!' ), $c->detach
      if $institute == $me->institute_id;

    my $another_user = $c->model('DB::User')->find(
        {
            institute_id => $institute,
            city_id      => $me->city_id,
        }
    );

    $self->status_bad_request( $c, message => 'No user in your city for institute you informed!' ), $c->detach
      unless $another_user;

    my $variables_names = {};
    my $valid_froms     = {};

    my $my_user   = $self->_load_variables( $c, $variables_names, \@variables, $me->id );
    my $from_user = $self->_load_variables( $c, $variables_names, \@variables, $another_user->id );

    my $out = {};

    while ( my ( $vid, $vfrom ) = each %$from_user ) {
        foreach my $from ( keys %$vfrom ) {
            $valid_froms->{$from} = 1;

            # ja existe, entao desmarcado
            if ( exists $my_user->{$vid}{$from} ) {
                $out->{$vid}{$from} = 0;
            }
            else {
                $out->{$vid}{$from} = 1;
            }
        }
    }

    $out = {
        checkbox        => $out,
        variables_names => $variables_names,
        periods         => [ sort keys %$valid_froms ]
    };

    $self->status_ok( $c, entity => $out );

}

sub _load_variables {

    my ( $self, $c, $variables_names, $variables, $user_id ) = @_;
    my $rs = $c->model('DB::ViewValuesByPeriod')->search(
        undef,
        {
            bind => [ [ { sqlt_datatype => 'int[]' }, $variables ], $user_id ],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    );
    my $out;
    while ( my $r = $rs->next ) {
        my $id = delete $r->{variable_id};

        $out->{$id}{ delete $r->{valid_from} } = 1;
        $variables_names->{$id} = delete $r->{variable_name};
    }

    return $out;
}

1;

