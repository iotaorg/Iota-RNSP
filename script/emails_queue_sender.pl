use strict;
use warnings;
use utf8;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Config::General;
use Template;

use Encode;
use JSON::XS;

my $file = "$Bin/../iota_local.conf";
$file = "$Bin/../iota.conf" unless -e $file;

my %config = new Config::General($file)->getall;

#use DDP;
# \%config;exit;
use Email::MIME;
use Email::Sender::Simple qw(sendmail);

my $transport_class = 'Email::Sender::Transport::' . $config{email}{transport}{class};
eval("use $transport_class");
die $@ if $@;

my $transport = $transport_class->new( %{ $config{email}{transport}{opts} } );

use Iota;
my $schema = Iota->model('DB');

my $config_tt = {
    INCLUDE_PATH => $config{email}{template_path},
    INTERPOLATE  => 1,
    POST_CHOMP   => 1,
    EVAL_PERL    => 0,

    ENCODING => 'utf8',

};
my $tt = Template->new($config_tt);

while (1) {
    $schema->txn_do(
        sub {
            my @not_sent = $schema->resultset('EmailsQueue')->search(
                {
                    sent => 0
                },
                {
                    for  => 'update',
                    rows => 10
                }
            )->all;

            print localtime(time) . ": " . @not_sent . " emails para enviar...\n";
            foreach my $mail (@not_sent) {

                my ( $body, $subject ) = ('') x 2;

                my $vars_js = $mail->variables;

                # $vars_js = encode( 'utf8', $vars_js );

                my $vars = eval { decode_json($vars_js) };
                my $title = $mail->subject;

                $vars->{ymd_to_human} = sub { Iota::View::HTML::ymd_to_human( undef, undef, @_ ) };
                $vars->{date4period} = sub { Iota::View::HTML::date4period( undef, undef, @_ ) };

                $tt->process( $mail->template, $vars, \$body, { binmode => ':utf8' } ) || die $tt->error(), "\n";
                $tt->process( \$title, $vars, \$subject ) || die $tt->error(), "\n";

                my $message = Email::MIME->create(
                    header => [
                        From    => $config{email}{from},
                        To      => $mail->to,
                        Subject => $subject
                    ],
                    attributes => {
                        content_type => "text/html",
                        encoding     => 'base64',
                        charset      => 'UTF-8',
                    },
                    body_str => $body
                );

                print "Enviando email para " . $mail->to . "...\n";
                eval { sendmail( $message, { transport => $transport } ) };
                print "Erro: $@\n---\n" if $@;

                $mail->sent(1);
                $mail->sent_at( \"now()" );
                $mail->text_status( $@ ? "Error: $@" : 'success' );
                $mail->update();
            }
        }
    );

    sleep 60;
}

print "Fim do programa\n";
exit(0);

