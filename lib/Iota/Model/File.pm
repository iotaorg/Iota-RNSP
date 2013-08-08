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
      ->search( { id => {in=>[ keys %varids ]} }, { select => [qw/id period/], as => [qw/id period/] } )->as_hashref->all;


    my %regsids = map { $_->{region_id} => 1} grep {$_->{region_id}} @{ $parse->{rows} };
    my @regs_db =
      $schema->resultset('Region')
      ->search( { id => {in=>[ keys %regsids ]} }, { select => [qw/id/], as => [qw/id/] } )->as_hashref->all;


    # se tem menos variaveis no banco do que as enviadas
    if ( @vars_db < keys %varids ) {
        $status = '';
        foreach my $id ( keys %varids ) {
            my $exists = grep { $_->{id} eq $id } @vars_db;

            $status .= "Variavel ID $id nao existe.\n"
              unless $exists;
        }
        $status .= 'Arrume o arquivo e envie novamente.';
    }elsif ( scalar keys %regsids != scalar @regs_db ) {
        $status = '';
        foreach my $id ( keys %regsids ) {
            my $exists = grep { $_->{id} eq $id } @regs_db;

            $status .= "Região ID $id nao existe.\n"
              unless $exists;
        }
        $status .= 'Arrume o arquivo e envie novamente.';
    }
    else {
        my %periods = map { $_->{id} => $_->{period} } @vars_db;

        my $user_id = $param{user_id};
        my $file = $schema->resultset('File')->create(
            {
                name        => $upload->filename,
                status_text => $status,
                created_by  => $user_id
            }
        );
        $file_id = $file->id;

        my $vv_rs  = $schema->resultset('VariableValue');
        my $rvv_rs = $schema->resultset('RegionVariableValue');

        $schema->txn_do(
            sub {
                my $with_region = {};
                my $without_region = {};
                my $cache_ref = {};
                # percorre as linhas e insere no banco
                # usando o modelo certo.

                foreach my $r ( @{ $parse->{rows} } ) {

                    my $ref = {
                        do_not_calc => 1,
                        cache_ref => $cache_ref
                    };
                    $ref->{variable_id}   = $r->{id};
                    $ref->{user_id}       = $user_id;
                    $ref->{value}         = $r->{value};
                    $ref->{value_of_date} = $r->{date};
                    $ref->{file_id}       = $file_id;

                    $ref->{observations} = $r->{obs};
                    $ref->{source}       = $r->{source};

                    if ( exists $r->{region_id} && $r->{region_id} ) {
                        $ref->{region_id} = $r->{region_id};

                        $with_region->{variables}{$r->{id}} = 1;
                        $with_region->{dates}{$r->{date}} = 1;
                        $with_region->{regions}{$r->{region_id}} = 1;

                        eval { $rvv_rs->_put( $periods{ $r->{id} }, %$ref ); };
                    }
                    else {
                        $without_region->{variables}{$r->{id}} = 1;
                        $without_region->{dates}{$r->{date}} = 1;

                        eval { $vv_rs->_put( $periods{ $r->{id} }, %$ref ); };
                    }
                    $status .= $@ if $@;
                    die $@ if $@;
                }


                my $data = Iota::IndicatorData->new( schema => $schema->schema );
                if (exists $with_region->{dates}){
                    $data->upsert(
                        indicators => [ $data->indicators_from_variables( variables => [
                            keys %{$with_region->{variables}}
                        ] ) ],
                        dates      => [
                            keys %{$with_region->{dates}}
                        ],
                        regions_id      => [
                            keys %{$with_region->{regions}}
                        ],
                        user_id    => $user_id
                    );
                }

                if (exists $without_region->{dates}){
                    $data->upsert(
                        indicators => [ $data->indicators_from_variables( variables => [
                            keys %{$without_region->{variables}}
                        ] ) ],
                        dates      => [
                            keys %{$without_region->{dates}}
                        ],
                        user_id    => $user_id
                    );
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
