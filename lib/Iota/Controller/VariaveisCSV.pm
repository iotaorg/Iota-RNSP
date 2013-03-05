
=head1 Download de arquivos das variaveis para montar excel de envio

=head2 Descrição

Download em /variaveis.csv

=cut

package Iota::Controller::VariaveisCSV;
use Moose;
BEGIN { extends 'Catalyst::Controller' }
use utf8;
use JSON::XS;

use Text::CSV_XS;


# download de todos os endpoints caem aqui
sub _download {
    my ( $self, $c ) = @_;

    my $file = 'variaveis_exemplo.csv';

    my $path = ($c->config->{downloads}{tmp_dir}||'/tmp') . '/' . lc $file;

    if (-e $path){
        my $epoch_timestamp = (stat($path))[9];
        unlink($path) if time() - $epoch_timestamp > 60;
    }
    $self->_download_and_detach($c, $path) if -e $path;

    # procula pela cidade, se existir.
    my $rs = $c->model('DB')->resultset('Variable')->as_hashref;



    my @lines = (
        ['ID da váriavel',
        'Nome',
        'Data',
        'Valor',
        ]
    );

    while(my $var = $rs->next){
        push @lines, [
            $var->{id},
            $var->{name},
            undef,undef
        ];
    }

    if ($0 && $0 =~ /\.t$/ ){
        $c->stash->{lines} = \@lines;
    }else{
        eval{$self->lines2file($c, $path, \@lines)};
    }

    if ($@){
        unlink($path);
        die $@;
    }
    $self->_download_and_detach($c, $path);
}



sub lines2file {
    my ( $self, $c, $path, $lines ) = @_;

    open my $fh, ">:encoding(utf8)", $path or die "$path: $!";

    my $csv = Text::CSV_XS->new ({ binary => 1, eol => "\r\n" }) or
    die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

    $csv->print ($fh, $_) for @$lines;


    close $fh or die "$path: $!";


}

sub _download_and_detach {
    my ( $self, $c, $path ) = @_;

    $c->response->content_type('text/csv');
    $c->response->headers->header('content-disposition' => "attachment;filename=variaveis_exemplo.csv");

    open(my $fh, '<:raw', $path);
    $c->res->body($fh);

    $c->detach;
}

sub download_csv : Chained('/') : PathPart('variaveis.csv') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}


1;


