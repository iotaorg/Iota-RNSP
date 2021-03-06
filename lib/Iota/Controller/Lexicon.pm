package Iota::Controller::Lexicon;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
use utf8;
use JSON::XS;

use DateTime;

sub base : Chained('/') PathPart(':lexicon') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    #$c->stash->{without_wrapper} = 1;
    $c->stash->{custom_wrapper} = 'iota-wrapper.tt';

    # tenta autenticar
    eval { $c->forward('/api/api_key_check') };

    # se foi um detach la de dentro, nao ta logado
    $c->res->body('failed to auth user')
      if ref $@ eq 'Catalyst::Exception::Detach';

    # morre se tiver qualquer erro!
    die $@ if $@;

    $c->stash->{lang_name} = {
        'es'    => 'Espanhol',
        'pt-br' => 'Português'
    };

    my $cur_lang = exists $c->req->cookies->{cur_lang} ? $c->req->cookies->{cur_lang}->value : 'pt-br';

    my %langs = map { $_ => 1 } split /,/, $c->config->{available_langs};
    $cur_lang = 'pt-br' unless exists $langs{$cur_lang};
    $c->set_lang($cur_lang);
}

sub env : Chained('base') PathPart('') CaptureArgs(0) {

}

sub load_pending : Chained('env') PathPart('pending') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $self->save_lexicons($c) if $c->req->method eq 'POST';

    my $min_length = exists $c->req->params->{min_length}
      && $c->req->params->{min_length} =~ /^[0-9]+$/ ? $c->req->params->{min_length} : undef;
    my $max_length =
      exists $c->req->params->{max_length}
      && $c->req->params->{max_length} =~ /^[0-9]+$/ ? $c->req->params->{max_length}
      : $c->stash->{count_only}                      ? undef
      :                                                60;

    my $filter_like = exists $c->req->params->{filter_like}
      && $c->req->params->{filter_like} !~ /^\s+$/ ? $c->req->params->{filter_like} : undef;

    $c->stash->{max_length}  = $max_length;
    $c->stash->{min_length}  = $min_length;
    $c->stash->{filter_like} = $filter_like;

    my $rs = $c->model('DB::Lexicon')->search(
        {
            lex_value => { like => '? %' },

            ( $c->user->id != 1 ? ( user_id => $c->user->id ) : () ),

            $filter_like ? ( lex_key => { like => \[ "'%'|| ? || '%'", [ foo => $filter_like ] ] } ) : (),

            ( $max_length || $min_length )
            ? (
                '-and' => [
                    $max_length ? ( \"length(lex_key) <= $max_length" ) : (),
                    $min_length ? ( \"length(lex_key) >= $min_length" ) : (),
                ]
              )
            : ()
        },
        {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            order_by     => [ 'lang', 'lex_key' ]
        }
    );

    if ( $c->stash->{count_only} ) {
        $c->stash->{count} = $rs->count;
        return;
    }

    my @lexs = $rs->all;
    $c->stash->{count} = scalar @lexs;

    for my $lex (@lexs) {
        my $group = 'word';
        $group = 'text'
          if ( length $lex->{lex_key} > 30 && $lex->{lex_key} =~ / / )
          || $lex->{lex_key} =~ /\n/o
          || $lex->{lex_key} =~ /</o;

        push @{ $c->stash->{lexicons}{ $lex->{origin_lang} }{ $lex->{lang} }{$group} }, $lex;
    }
}

sub save_lexicons {
    my ( $self, $c ) = @_;

    my $rs = $c->model('DB::Lexicon')->search( { ( $c->user->id != 1 ? ( user_id => $c->user->id ) : () ), } );

    my $i = 0;
    while ( my ( $name, $value ) = each %{ $c->req->params } ) {
        next unless $value;
        next unless $name =~ /^lex_(\d+)/;

        my $id = $1;
        my $it = $rs->search( { id => $id } );
        $it->update( { lex_value => $value } );

        $i++;
    }

    $c->lexicon_reload_all() if $i;

    $c->response->cookies->{'reload_lex'} = {
        value   => 1,
        path    => '/',
        expires => '+3600h',
    };

    $c->stash->{message} = "$i " . $c->loc('textos traduzidos');
}

sub pending : Chained('load_pending') PathPart('') Args(0) {

}

sub pending_count : Chained('env') PathPart('pending/count') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{count_only} = 1;

    $self->load_pending($c);

    $c->res->body(qq|{"count":${\$c->stash->{count}}}|);
}

__PACKAGE__->meta->make_immutable;

1;
