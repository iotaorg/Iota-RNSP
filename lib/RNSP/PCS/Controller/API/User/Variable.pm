
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
                "variable_id": 63,
                "value": "123",
                "name": "Foo Bar",
                "value_url": "http://localhost/api/variable/63/value/37",
                "explanation": "a foo with bar",
                "value_id": 37,
                "cognomen": "foobar",
                "type": "int",
                "value_of_date": ...
            },
            {
                "variable_id": 64,
                "value": null,
                "name": "Foo Bar2",
                "value_url": null,
                "explanation": "a foo with bar2",
                "value_id": null,
                "cognomen": "foobar2",
                "type": "num",
                "value_of_date": ...
            }
        ]
    }

=cut

sub list_GET {
  my ( $self, $c ) = @_;

    my @list = $c->stash->{collection}->search_rs( {
        'values.user_id' => $c->stash->{user}->id
    }, { prefetch => ['values'] } )->as_hashref->all;
    my @objs;

    foreach my $obj (@list){
        push @objs, {

            (map { $_ => $obj->{$_} } qw(name type cognomen explanation)),
            variable_id => $obj->{id},
            value_id => $obj->{values}[0]{id},
            value => $obj->{values}[0]{value},
            value_of_date => $obj->{values}[0]{value_of_date},
            value_url => $obj->{values}[0]{id} ?
                ($c->uri_for_action( $c->controller('API::Variable::Value')->action_for('variable'), [ $obj->{id}, $obj->{values}[0]{id} ] )->as_string) : undef,

        }
    }
    $self->status_ok(
        $c,
        entity => {
        variables => \@objs
        }
    );
}


with 'RNSP::PCS::TraitFor::Controller::Search';
1;

