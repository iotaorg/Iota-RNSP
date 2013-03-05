
package Iota::PCS::Controller::API::Variable::ValueViaFile;

use Moose;
use JSON;

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/variable/base') : PathPart('value_via_file') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{collection} = $c->model('DB::VariableValue');

}

sub file: Chained('base') : PathPart('') : Args(0) ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub file_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
        unless $c->check_any_user_role(qw(admin user));
    my $upload = $c->req->upload('arquivo');
    eval{
        if ($upload){
            my $user_id = $c->user->id;

            $c->logx('Enviou arquivo ' . $upload->basename);

            my $file = $c->model('File')->process(
                user_id => $user_id,
                upload  => $upload,
                schema  => $c->model('DB'),
                app     => $c
            );

            $c->res->body(to_json( $file ));

        }else{
            die "no upload found\n";
        }
    };
    $c->res->body(to_json({ error => "$@" })) if $@;

    $c->detach;

}




1;

