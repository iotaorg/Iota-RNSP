
=head1 API

=head2 Descrição

A API do Iota é uma API primariamente desenvolvida utilizando RESTful HTTP. Para realizar uma ação são feitas requisições HTTP a determinados endpoints utilizando alguns parâmetros e recebendo em resposta um conteúdo formatado.

A formatação dos parâmetros das requisições obedecem ao seguinte padrão:

(entidade + ".")* + (ação + ".")* + nome do parâmetro.

Ex: user.login.email, user.preferences.update.name, user.create.address_street, organization.update.cnpj, organization.user.update.cnpj

Nesta versão inicial as respostas HTTP possuem o content-type 'application/json' e no corpo um texto em formato JSON.

=head3 Nota

=over 4

=item * Por enquanto todas as requisições devem possuir Content-Type: application/x-www-form-urlencoded

=item * O verbo PUT ainda não é suportado, no momento ele é emulado através de um POST

=item * Espera-se que todos os requests sejam migrados para json-encoded.

=back

=head2 Endpoints

=head3 /api/login

=head4 POST

Realiza a autenticação do usuário retornando uma api_key no corpo da resposta.

=head3 /api/logout

=head4 GET

Desloga o usuário do sistema expirando a api_key.


=cut

package Iota::Controller::API;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config( default => 'application/json' );

use Digest::SHA1 qw(sha1_hex);
use Time::HiRes qw(time);
use Storable qw/nfreeze thaw/;
use Redis;
my $redis = Redis->new;

sub api_key_check : Private {
    my ( $self, $c ) = @_;

    my $api_key = $c->req->param('api_key')
      || ( $c->req->data ? $c->req->data->{api_key} : undef );

    unless ( ref $c->user eq 'Iota::TestOnly::Mock::AuthUser' ) {
        $self->status_forbidden( $c, message => "access denied" ), $c->detach
          unless defined $api_key;

        my $cache_key    = "session-for-$api_key";
        my $user_session = $redis->get($cache_key);
        if ($user_session) {
            $user_session = thaw($user_session);
            $user_session->result_source->schema( $c->model('DB')->schema );
        }
        else {
            $user_session = $c->model('DB::UserSession')->search(
                {
                    api_key     => $api_key,
                    valid_until => { '>=' => \'now()' },
                }
            )->first;

            $redis->setex( $cache_key, 60 * 5, $user_session ? nfreeze($user_session) : '' );
        }

        my $user = $user_session ? $c->find_user( { id => $user_session->user_id } ) : undef;

        $self->status_forbidden( $c, message => "access denied", ), $c->detach
          unless defined $api_key && $user;

        $c->stash->{logged_user} = $user;

        $c->set_authenticated($user);
    }
    else {
        my $user = $c->find_user( { id => $c->user->id } );
        $c->stash->{logged_user} = $user;
    }

}

sub root : Chained('/') : PathPart('api') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->response->headers->header( 'charset' => 'utf-8' );

}

sub public_lexicons : Chained('root') PathPart('public/lexicons') Args(0) {
    my ( $self, $c ) = @_;

    my $rs = $c->model('DB::Lexicon')->search( undef, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' } );

    my $out = {};
    while ( my $r = $rs->next ) {
        $out->{ $r->{lang} }{ $r->{lex_key} } = $r->{lex_value};
    }

    $self->status_ok(
        $c,
        entity => {
            lex     => $out,
            langs   => [ split /,/, $c->config->{forced_langs} ],
            default => $c->config->{default_lang}
        }
    );

}

sub lexicons : Chained('base') PathPart('lexicons') Args(0) {
    my ( $self, $c ) = @_;

    my $ref = $c->req->params->{lex};
    $ref = [$ref] unless ref $ref eq 'ARRAY';

    $c->set_lang( $c->config->{default_lang} );
    foreach my $v (@$ref) {
        next
          if $v =~ /^\s*$/
          || $v !~ /[a-z]/i
          || $v =~ /^\s*[0-9]+\s*$/;

        $c->loc( $v, 'pt-br' );
    }

    $self->status_ok( $c, entity => { saved => 1 } );
}

sub login : Chained('root') : PathPart('login') : Args(0) : ActionClass('REST') {
}

sub login_POST {
    my ( $self, $c ) = @_;

    if ( exists $c->req->params->{'user.login.email'} ) {
        my $login_disabled = $c->model('DB::User')->search(
            {
                email  => lc $c->req->params->{'user.login.email'},
                active => 1,
            },
            { result_class => 'DBIx::Class::ResultClass::HashRefInflator', columns => ['password'] }
        )->next;

        if ( $login_disabled && $login_disabled->{password} eq 'accmoved' ) {
            $self->status_ok( $c, entity => { accmoved => 1 } );
            $c->detach;
        }
    }

    my $dm = $c->model('DataManager');

    $self->status_bad_request( $c, message => 'Login invalid' ), $c->detach
      unless $dm->success;

    if ( $c->authenticate( { map { $_ => $c->req->param( 'user.login.' . $_ ) } qw(email password) } ) ) {
        my $item = $c->user->sessions->create(
            {
                api_key => sha1_hex( rand(time) ),
            }
        );

        $c->user->discard_changes;

        #$c->log->info("Login de " . $c->user->as_string ." com sucesso");
        my %attrs = $c->user->get_inflated_columns;
        $attrs{api_key} = $item->api_key;

        $attrs{roles} = [ map { $_->name } $c->model('DB::User')->search( { id => $c->user->id } )->first->roles ];

        delete $attrs{password};
        $attrs{created_at} = $attrs{created_at}->datetime;

        $self->status_ok( $c, entity => \%attrs );
    }
    else {
        $c->log->info( "Falha na tentativa do login de " . $c->req->param('user.login.email') . "." );
        $self->status_bad_request( $c, message => 'Login invalid(2)' );
    }

}

sub logout : Chained('base') : PathPart('logout') : Args(0) : ActionClass('REST') {
}

sub logout_GET {
    my ( $self, $c ) = @_;
    $c->logout;
    $self->status_ok( $c, entity => { logout => 'ok' } );
}

sub logged_in : Chained('root') : PathPart('') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->forward('api_key_check');
}

sub base : Chained('logged_in') : PathPart('') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    my $inp = $c->req->params;
    if (   !exists $c->stash->{rest}{error}
        && $c->req->method =~ /PUT|POST/
        && ref $inp eq 'HASH'
        && !exists $ENV{HARNESS_ACTIVE} ) {

        $c->set_lang( $c->config->{default_lang} );

        foreach my $k ( keys %{$inp} ) {
            next
              if $k =~ /password/
              || $k =~ /email/
              || $k =~ /formula/
              || $k =~ /polygon_path/
              || $k =~ /name_url/
              || $k =~ /(city|user|state|country|city\.region)\.(create|update)\.name/
              || $k eq 'api_key'
              || $k eq 'arquivo'
              || $k eq 'lex';

            my $v = $inp->{$k};
            next if ref $v ne '';

            next
              if $v =~ /^\s*$/
              || $v !~ /[a-z]/i
              || $v =~ /^\s*[0-9]+\s*$/;

            $c->loc($v);
        }
    }
}

1;

