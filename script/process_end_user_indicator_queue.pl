package FakeUser;

use Moose;

has 'cur_lang' => ( is => 'rw', isa => 'Str' );

no Moose;
__PACKAGE__->meta->make_immutable;

package FakeCatalyst;

use Moose;

has 'user'   => ( is => 'rw', isa => 'Any' );
has 'config' => ( is => 'ro', isa => 'Any' );

sub user_in_realm { 0 }

no Moose;
__PACKAGE__->meta->make_immutable;

package main;

use strict;
use warnings;
use utf8;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Encode;
use JSON::XS;

use Iota;
my $schema = Iota->model('DB');

my $fake_c = FakeCatalyst->new( user => FakeUser->new( cur_lang => 'pt-br' ), config => Iota->config );

sub loc {
    CatalystX::Plugin::Lexicon::loc( $fake_c, join( ' ', @_ ), 'pt-br' );
}

my @users = $schema->resultset('EndUserIndicatorQueue')->search(
    {
        email_sent => 0
    },
    {
        group_by => ['end_user_id'],
        columns  => ['end_user_id'],
    }
)->all;

print localtime(time) . ": " . @users . " usuarios para gerar templates...\n";

foreach my $user (@users) {

    $schema->txn_do(
        sub {

            my $rs = $schema->resultset('EndUserIndicatorQueue')->search(
                {
                    email_sent  => 0,
                    end_user_id => $user->end_user_id
                }
            );

            my $num_indicadores = $schema->resultset('EndUserIndicator')->search(
                {
                    end_user_id => $user->end_user_id
                },
                {
                    select => [ { count => { distinct => 'indicator_id' } } ],
                    as     => ['count']
                }
            )->next->get_column('count');

            my @reports = $rs->search(
                undef,
                {
                    prefetch => [
                        'end_user',
                        'indicator',

                        { 'region' => 'upper_region' },
                        {
                            'user' => { 'city' => [ 'country', 'state' ] }
                        }

                    ],

                    #for => 'update',
                    order_by => \
                      "date_trunc('seconds', me.created_at), me.user_id, me.indicator_id, me.operation_type DESC",
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator'
                }
            )->all;

            # TODO perguntar o idioma do end-user no cadastro!
            CatalystX::Plugin::Lexicon::set_lang( $fake_c, 'pt-br' );

            my $end_user = $reports[0]->{end_user};

            my $subject = loc 'Iota - Novas informações sobre os indicadores que você segue!';

            my $queue = $schema->resultset('EmailsQueue');
            $queue->create(
                {
                    to        => $end_user->{email},
                    subject   => $subject,
                    template  => 'end_user_indicator.tt',
                    variables => encode_json(
                        {
                            reports => \@reports,

                            name => $end_user->{name},

                            l_evento        => loc('Evento'),
                            l_aconteceu_em  => loc('Aconteceu em'),
                            l_indicador     => loc('Indicador'),
                            l_data_do_valor => loc('Data do valor'),
                            l_valor         => loc('Valor'),
                            l_cidade        => loc('Cidade'),
                            l_regiao        => loc('Região'),
                            l_variacao      => loc('Variação'),
                            l_tipo_do_valor => loc('Tipo do valor'),
                            l_fontes        => loc('Fontes'),

                            l_ola      => loc('Olá'),
                            l_removido => loc('Removido'),
                            l_inserido => loc('Inserido'),

                            l_ativo   => loc('Ativo'),
                            l_inativo => loc('Inativo'),
                            l_sumario => loc('Sumário'),

                            l_resumo_antes_tabela =>
                              loc('Abaixo estão as alterações dos indicadores que você acompanha.'),

                            l_resumo_depois_tabela => loc('Você acompanha __NUM__ indicadores.'),

                            num_indicadores => $num_indicadores

                        }
                    ),
                    sent => 0
                }
            );

            $rs->delete;

        }
    );

}

print "Fim do programa\n";
exit(0);

