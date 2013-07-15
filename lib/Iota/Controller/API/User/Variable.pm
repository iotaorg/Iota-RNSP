
package Iota::Controller::API::User::Variable;

use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/user/object') : PathPart('variable') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{user_rs} = $c->stash->{object};
    $c->stash->{user}    = $c->stash->{object}->next;

    $c->stash->{collection} = $c->model('DB::Variable');

}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}

=pod

listar variaveis com ou sem valores do usuario

GET /api/user/ID/variable

opcional enviar:
 ?valid_from_begin=yyyy-mm-dd
 ?valid_from_end=yyyy-mm-dd
 ?variable_id=i

Retorna:

    {
        "variables": [
            {
                "variable_id": 207,
                "period": "yearly",
                "explanation": "a foo with bar",
                "cognomen": "foobar",
                "name": "Foo Bar",
                "values": [
                    {
                        "valid_from": "2010-01-01",
                        "value": "123",
                        "url": "http://localhost/api/variable/207/value/116",
                        "valid_until": "2011-01-01",
                        "value_of_date": "2010-02-14 17:24:32",
                        "id": 116,
                        source,
                        observations
                    }, ...
                    pode ter varios valores de anos (por que é anual) diferentes
                ],
                "type": "int"
            },
            {
                "variable_id": "208",
                "period": "yearly",
                "explanation": "a not foo with bar",
                "cognomen": "foobar2",
                "name": "Foo Bar2",
                "values": [],
                "type": "num",

            },
            ....
        ]
    }

=cut

sub list_GET {
    my ( $self, $c ) = @_;

    my $rs = $c->stash->{collection};

    $rs = $rs->search( { is_basic => $c->req->params->{is_basic} } )
      if ( defined $c->req->params->{is_basic} );

    $rs = $rs->search( { id => $c->req->params->{variable_id} } )
      if ( defined $c->req->params->{variable_id} );

    my @list = $rs->as_hashref->all;
    my @objs;
    my $region_id = exists $c->req->params->{region_id} ? $c->req->params->{region_id} : undef;
    my $vtable = $region_id ? 'region_variable_values' : 'values';

    my $region =
      exists $c->req->params->{region_id} ? $c->model('DB::Region')->find( $c->req->params->{region_id} ) : undef;

    my $city_id = $c->stash->{user}->city_id || '1';    # test fix

    my $active_value = exists $c->req->params->{active_value} ? $c->req->params->{active_value} : 1;

    foreach my $obj (@list) {

        my $where = {};
        $where->{valid_from}{'>='} = $c->req->params->{valid_from_begin} if exists $c->req->params->{valid_from_begin};
        $where->{valid_from}{'<='} = $c->req->params->{valid_from_end}   if exists $c->req->params->{valid_from_end};

        my @values = $rs->search( { id => $obj->{id} } )->next->$vtable->search(
            {
                user_id => $c->stash->{user}->id,
                ( ( region_id => $region_id ) x !!$region_id ),

                ( defined $region && $region->depth_level == 2 ? ( active_value => $active_value ) : () ),
                %$where,
            }
        )->as_hashref->all;

        push @objs, {
            ( map { $_ => $obj->{$_} } qw(name type cognomen explanation period measurement_unit) ),
            variable_id => $obj->{id},
            values      => [
                map {
                    +{
                        value         => $_->{value},
                        value_of_date => $_->{value_of_date},
                        source        => $_->{source},
                        observations  => $_->{observations},
                        valid_from    => $_->{valid_from},

                        (active_value  => $_->{active_value}) x!! exists $_->{active_value},
                        (generated_by_compute => $_->{generated_by_compute}?1:0) x!! exists $_->{generated_by_compute},

                        valid_until   => $_->{valid_until},
                        id            => $_->{id},

                        url => $region_id
                        ? $c->uri_for_action( $c->controller('API::City::Region::Value')->action_for('variable'),
                            [ $city_id, $region_id, $_->{id} ] )->as_string
                        : $c->uri_for_action( $c->controller('API::Variable::Value')->action_for('variable'),
                            [ $obj->{id}, $_->{id} ] )->as_string

                      }
                } sort { $a->{valid_from} cmp $b->{valid_from} } @values
            ],
        };
    }

    $self->status_ok( $c, entity => { variables => \@objs } );
}

#with 'Iota::TraitFor::Controller::Search';
1;

