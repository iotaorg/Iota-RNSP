package Iota::Model::File;
use Moose;
use utf8;
use JSON qw/encode_json/;

use Iota::Model::File::XLSX;
use Iota::Model::File::XLS;
use Iota::Model::File::CSV;

sub process {
    my ( $self, %param ) = @_;

    my $upload = $param{upload};
    my $schema = $param{schema};

    my $parse;
    eval {
        if ( $upload->filename =~ /xlsx$/ ) {
            $parse = Iota::Model::File::XLSX->new->parse( $upload->tempname );
        }
        elsif ( $upload->filename =~ /xls$/ ) {
            $parse = Iota::Model::File::XLS->new->parse( $upload->tempname );
        }
        elsif ( $upload->filename =~ /csv$/ ) {
            $parse = Iota::Model::File::CSV->new->parse( $upload->tempname );
        }
    };
    die $@ if $@;
    die "file not supported!\n" unless $parse;

    my $status = $@ ? $@ : '';

    $status .= 'Linhas aceitas: ' . $parse->{ok} . "\n";
    $status .= 'Linhas ignoradas: ' . $parse->{ignored} . "\n" if $parse->{ignored};
    $status .= "Cabeçalho não encontrado!\n" unless $parse->{header_found};

    my %varids = map { $_->{id} => 1 } @{ $parse->{rows} };
    my $file_id;

    my @vars_db =
      $schema->resultset('Variable')
      ->search( { id => [ keys %varids ] }, { select => [qw/id period/], as => [qw/id period/] } )->as_hashref->all;

    # se tem menos variaveis no banco do que as enviadas
    if ( @vars_db < keys %varids ) {
        $status = '';
        foreach my $id ( keys %varids ) {
            my $exists = grep { $_->{id} eq $id } @vars_db;

            $status .= "Variavel ID $id nao existe.\n"
              unless $exists;
        }
        $status .= 'Arrume o arquivo e envie novamente.';
    }
    else {
        my %periods = map { $_->{id} => $_->{period} } @vars_db;

        my $file = $schema->resultset('File')->create(
            {
                name        => $upload->filename,
                status_text => $status,
                created_by  => $param{user_id}
            }
        );
        $file_id = $file->id;

        $schema->txn_do(
            sub {
                # percorre as linhas e insere no banco
                # usando o modelo certo.
                foreach my $r ( @{ $parse->{rows} } ) {
                    my $ref = {};

                    $ref->{variable_id}   = $r->{id};
                    $ref->{user_id}       = $param{user_id};
                    $ref->{value}         = $param{value};
                    $ref->{value_of_date} = $r->{date};
                    $ref->{file_id}       = $file_id;

                    eval { $schema->resultset('VariableValue')->_put( $periods{ $r->{id} }, %$ref ); };
                    $status .= $@ if $@;
                    die $@ if $@;
                }
            }
        );
        $file->update( { status_text => $status } );

    }

    return {
        status  => $status,
        file_id => $file_id
    };

}

1;
