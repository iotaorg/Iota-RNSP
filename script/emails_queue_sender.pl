use strict;
use warnings;
use utf8;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Config::General;
use Template;

use Encode;
use JSON qw / decode_json /;

my %config = new Config::General("$Bin/../mu_web_app.conf")->getall;

use Email::MIME;
use Email::Sender::Simple qw(sendmail);

my $transport_class =
  'Email::Sender::Transport::' . $config{email}{transport}{class};
eval("use $transport_class");
die $@ if $@;

my $transport = $transport_class->new( %{ $config{email}{transport}{opts} } );

use Mu::Web::App;
my $schema = Mu::Web::App->model('DB');

my $config_tt = {
  INCLUDE_PATH => $config{email}{template_path},
  INTERPOLATE  => 1,
  POST_CHOMP   => 1,
  EVAL_PERL    => 0,
};
my $tt = Template->new($config_tt);

my @not_sent = $schema->resultset('EmailsQueue')->search( { sent => 0 } )->all;

print @not_sent . " emails para enviar...\n";
foreach my $mail (@not_sent) {

  my ( $body, $subject ) = ('') x 2;

  my $vars  = decode_json( $mail->variables );
  my $title = $mail->subject;

  $tt->process( $mail->template, $vars, \$body )    || die $tt->error(), "\n";
  $tt->process( \$title,         $vars, \$subject ) || die $tt->error(), "\n";
  my $message = Email::MIME->create(
    header => [
      From    => $config{email}{from},
      To      => $mail->to,
      Subject => $subject
    ],
    attributes => {
      content_type => "text/html",
      encoding     => 'quoted-printable',
      charset      => 'UTF-8',
    },
    body_str => Encode::decode( "UTF-8", $body )
  );

  print "Enviando email para " . $mail->to . "...\n";
  eval { sendmail( $message, { transport => $transport } ) };
  print "Erro: $@\n---\n" if $@;

  $mail->sent(1);
  $mail->sent_at( \"now()" );
  $mail->text_status( $@ ? 'success' : "Error: $@" );
  $mail->update();
}

print "Fim do programa\n";
exit(0);

