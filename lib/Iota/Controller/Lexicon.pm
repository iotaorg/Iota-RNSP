package Iota::Controller::Lexicon;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
use utf8;
use JSON::XS;

use DateTime;

sub base : Chained('/') PathPart(':lexicon') CaptureArgs(0) {
    my ($self, $c) = @_;
    #$c->stash->{without_wrapper} = 1;
    $c->stash->{custom_wrapper} = 'iota-wrapper.tt';

    # tenta autenticar
    eval{ $c->forward('/api/api_key_check') };
    # se foi um detach la de dentro, nao ta logado
    $c->res->body('failed to auth user')
        if ref $@ eq 'Catalyst::Exception::Detach';
    # morre se tiver qualquer erro!
    die $@ if $@;

    $c->stash->{lang_name} = {
        'es' => 'Espanhol'
    };
}


sub env : Chained('base') PathPart('') CaptureArgs(0) {

}

sub load_pending : Chained('env') PathPart('pending') CaptureArgs(0) {
    my ($self, $c) = @_;

    $self->save_lexicons($c) if $c->req->method eq 'POST';

    my @lexs = $c->model('DB::Lexicon')->search({
        lex_value => { like => '? %' },
        user_id   => $c->user->id
    }, {
        result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        order_by     => ['lang', 'lex_key']
    })->all;

    for my $lex (@lexs){
        my $group = 'word';
        $group = 'text' if (length $lex->{lex_key} > 30 && $lex->{lex_key} =~ / /) || $lex->{lex_key} =~ /\n/o || $lex->{lex_key} =~ /</o;

        push @{$c->stash->{lexicons}{$lex->{lang}}{$group} }, $lex;
    }


}

sub save_lexicons {
    my ($self, $c) = @_;

    my $rs = $c->model('DB::Lexicon')->search({
        user_id   => $c->user->id
    });
    while (my ($name, $value) = each %{$c->req->params}) {
        next unless $value;
        next unless $name =~ /^lex_(\d+)/;

        my $id = $1;
        my $it = $rs->search( { id => $id } );
        $it->update( { lex_value => $value } );

    }

}


sub pending : Chained('load_pending') PathPart('') Args(0) {

}


__PACKAGE__->meta->make_immutable;

1;
