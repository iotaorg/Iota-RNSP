
package Iota::Controller::API::Log;

use Moose;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/base') : PathPart('log') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{collection} = $c->model('DB::ActionLog');
    $c->stash->{no_loc}     = 1;

}

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') {
}

=pod

listar os eixos

GET /api/log?user_id=1234

user_id opcional

Retorna:

    {
        "logs": [
            {
                "date": "2012-11-26T17:01:24",
                "ip": "127.0.0.1",
                "user": {
                    "nome": "admin",
                    "id": 1
                },
                "url": "POST /api/variable",
                "indicator_id": null,
                "message": "Adicionou variavel Foo Bar0"
            },
        ]
    }

=cut

sub list_GET {
    my ( $self, $c ) = @_;
    my $criteria;

    $criteria->{user_id} = $c->req->params->{user_id}
      if exists $c->req->params->{user_id};

    my @list = $c->stash->{collection}->search( $criteria, {
        order_by => [ {'-desc' => 'dt_when'} ],
        rows => 100,
        prefetch => ['user']
        } )->all;
    my @objs;

    foreach my $obj (@list) {
        push @objs, {

            ( map { $_ => $obj->$_ } qw(url message ip indicator_id) ),
            date => $obj->dt_when->datetime,
            user => ( $obj->user ? { id => $obj->user->id, nome => $obj->user->name } : undef ),

        };
    }

    $self->status_ok( $c, entity => { logs => \@objs } );
}

with 'Iota::TraitFor::Controller::Search';
1;

