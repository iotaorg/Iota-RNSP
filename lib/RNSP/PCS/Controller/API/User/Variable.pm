
package RNSP::PCS::Controller::API::User::Variable;

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

GET /api/variable

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
                        "id": 116
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
                "type": "num"
            },
            ....
        ]
    }

=cut

sub list_GET {
  my ( $self, $c ) = @_;

    my $rs = $c->stash->{collection}->search_rs({
    -or => [
         'values.user_id' => $c->stash->{user}->id,
        'values.user_id' => undef,
    ] }, { prefetch => ['values'] } );

    $rs = $rs->search({is_basic => $c->req->params->{is_basic}})
        if (defined $c->req->params->{is_basic});

    my @list = $rs->as_hashref->all;
    my @objs;

    foreach my $obj (@list){
        push @objs, {

            (map { $_ => $obj->{$_} } qw(name type cognomen explanation period)),
            variable_id => $obj->{id},
            values => [ map {+{
                    value         => $_->{value},
                    value_of_date => $_->{value_of_date},
                    valid_from    => $_->{valid_from},
                    valid_until   => $_->{valid_until},
                    id            => $_->{id},
                    url           =>  $c->uri_for_action( $c->controller('API::Variable::Value')->action_for('variable'), [ $obj->{id}, $_->{id} ] )->as_string
                }} @{$obj->{values}}
           ],
        }
    }

    $self->status_ok(
        $c,
        entity => {
        variables => \@objs
        }
    );
}


#with 'RNSP::PCS::TraitFor::Controller::Search';
1;

