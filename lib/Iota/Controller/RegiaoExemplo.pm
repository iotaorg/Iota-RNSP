
=head1 Download de arquivos das regioes dos usuarios

=head2 Descrição

Download em /variaveis.csv

=cut

package Iota::Controller::RegiaoExemplo;
use Moose;
BEGIN { extends 'Catalyst::Controller' }
use utf8;
use JSON::XS;

use Text::CSV_XS;

# download de todos os endpoints caem aqui
sub _download {
    my ( $self, $c ) = @_;

    my $file = 'variaveis_exemplo.csv';

    my $path = ( $c->config->{downloads}{tmp_dir} || '/tmp' ) . '/' . lc $file;

    if ( -e $path ) {
        my $epoch_timestamp = ( stat($path) )[9];
        unlink($path) if time() - $epoch_timestamp > 60;
    }
    $self->_download_and_detach( $c, $path ) if -e $path;

    # procula pela cidade, se existir.
    my $rs = $c->stash->{collation};

    my @lines =
      ( [ 'ID da regiao', 'Região', 'Subregião', 'ID da variavel', 'Data', 'Valor', 'fonte', 'observacao' ] );

    while ( my $var = $rs->next ) {
        if ( $var->{depth_level} == 2 ) {
            push @lines, [ $var->{id}, $var->{name}, '-', undef, undef, undef, undef, undef ];
        }
        else {
            push @lines, [ $var->{id}, $var->{upper_region}{name}, $var->{name}, undef, undef, undef, undef, undef ];
        }
    }

    if ( $0 && $0 =~ /\.t$/ ) {
        $c->stash->{lines} = \@lines;
    }
    else {
        eval { $self->lines2file( $c, $path, \@lines ) };
    }

    if ($@) {
        unlink($path);
        die $@;
    }
    $self->_download_and_detach( $c, $path );
}

sub lines2file {
    my ( $self, $c, $path, $lines ) = @_;

    open my $fh, ">:encoding(utf8)", $path or die "$path: $!";
    if ( $path =~ /csv$/ ) {
        my $csv = Text::CSV_XS->new( { binary => 1, eol => "\r\n" } )
          or die "Cannot use CSV: " . Text::CSV_XS->error_diag();

        $csv->print( $fh, $_ ) for @$lines;

    }
    elsif ( $path =~ /xls$/ ) {
        binmode($fh);
        my $workbook = Spreadsheet::WriteExcel->new($fh);

        # Add a worksheet
        my $worksheet = $workbook->add_worksheet();

        #  Add and define a format
        my $bold = $workbook->add_format();    # Add a format
        $bold->set_bold();

        # Write a formatted and unformatted string, row and column notation.
        my $total = @$lines;

        for ( my $row = 0 ; $row < $total ; $row++ ) {

            if ( $row == 0 ) {
                $worksheet->write( $row, 0, $lines->[$row], $bold );
            }
            else {
                my $total_col = @{ $lines->[$row] };
                for ( my $col = 0 ; $col < $total_col ; $col++ ) {
                    my $val = $lines->[$row][$col];

                    if ( $val && $val =~ /^\=/ ) {
                        $worksheet->write_string( $row, $col, $val );
                    }
                    else {
                        $worksheet->write( $row, $col, $val );
                    }
                }
            }
        }

    }
    else {
        die("not a valid format");
    }
    close $fh or die "$path: $!";

}

sub _download_and_detach {
    my ( $self, $c, $path ) = @_;

    if ( $c->stash->{type} =~ /(csv)/ ) {
        $c->response->content_type('text/csv');
    }
    elsif ( $c->stash->{type} =~ /(xls)/ ) {
        $c->response->content_type('application/vnd.ms-excel');
    }
    $c->response->headers->header( 'content-disposition' => "attachment;filename=regiao_exemplo.$1" );

    open( my $fh, '<:raw', $path );
    $c->res->body($fh);

    $c->detach;
}

sub load_user : Chained('/institute_load') : PathPart('dados/usuario') : CaptureArgs(1) {
    my ( $self, $c, $user_id ) = @_;

    my $user = $c->model('DB')->resultset('User')->find($user_id);

    my $rs = $c->model('DB')->resultset('Region')->search(
        { 'me.city_id' => eval { $user->city_id } },
        {
            prefetch => 'upper_region',
            order_by => [ \'COALESCE(me.upper_region, me.id)' ]
        }
    )->as_hashref;

    $c->stash->{collation} = $rs;
}

sub download_csv : Chained('load_user') : PathPart('regiao_exemplo.csv') : Args(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'csv';
    $self->_download($c);
}

sub download_xls : Chained('load_user') : PathPart('regiao_exemplo.xls') : Args(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xls';
    $self->_download($c);
}

1;

