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
    $status .= 'Linhas ignoradas: ' . $parse->{ignored} . "\n"
      if $parse->{ignored};
    $status .= "Cabeçalho não encontrado!\n" unless $parse->{header_found};

    my %varids = map { $_->{id} => 1 } @{ $parse->{rows} };
    my $file_id;

    my @vars_db =
      $schema->resultset('Variable')
      ->search( { id => { in => [ keys %varids ] } },
        { select => [qw/id period type/], as => [qw/id period type/] } )
      ->as_hashref->all;
    my %var_vs_id = map { $_->{id} => $_ } @vars_db;

    my %regsids =
      map { $_->{region_id} => 1 } grep { $_->{region_id} } @{ $parse->{rows} };
    my @regs_db =
      $schema->resultset('Region')
      ->search( { id => { in => [ keys %regsids ] } },
        { select => [qw/id depth_level/], as => [qw/id depth_level/] } )
      ->as_hashref->all;

    my %reg_vs_id = map { $_->{id} => $_ } @regs_db;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                localtime(time);
    $year += 1900;


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
    elsif ( scalar keys %regsids != scalar @regs_db ) {
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
        my $file    = $schema->resultset('File')->create(
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
                my $with_region    = {};
                my $without_region = {};
                my $cache_ref      = {};

                # percorre as linhas e insere no banco
                # usando o modelo certo.
                my $c = 0;

                foreach my $r ( @{ $parse->{rows} } ) {
                    $c++;

                    my $variable = $var_vs_id{ $r->{id} };

                    my $type = $variable->{type};

                    my $old_value = $r->{value};

                    $r->{value} =
                      $self->_verify_variable_type( $r->{value}, $type );

                    if ( !defined $r->{value} ) {
                        $status =
"Valor '$old_value' não é um número válido [registro número $c]. Por favor, envie formatado corretamente.";

                        #  die "invalid number";
                    }
                    if ( $r->{date} >= $year ) {
                        $status =
"Ano '".$r->{date}."' recusada, envie dados anteriores à $year";

                        #  die "invalid number";
                    }
                    

                    my $ref = {
                        do_not_calc => 1,
                        cache_ref   => $cache_ref
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

                        $with_region->{variables}{ $r->{id} }      = 1;
                        $with_region->{dates}{ $r->{date} }        = 1;
                        $with_region->{regions}{ $r->{region_id} } = 1;

                        eval { $rvv_rs->_put( $periods{ $r->{id} }, %$ref ); };
                    }
                    else {
                        $without_region->{variables}{ $r->{id} } = 1;
                        $without_region->{dates}{ $r->{date} }   = 1;

                        eval { $vv_rs->_put( $periods{ $r->{id} }, %$ref ); };
                    }
                    $status .= "$@" if $@;
                    die $@ if $@;
                }
                my $data =
                  Iota::IndicatorData->new( schema => $schema->schema );
                if ( exists $with_region->{dates} ) {
                    $data->upsert(
                        indicators => [
                            $data->indicators_from_variables(
                                variables =>
                                  [ keys %{ $with_region->{variables} } ]
                            )
                        ],
                        dates      => [ keys %{ $with_region->{dates} } ],
                        regions_id => [ keys %{ $with_region->{regions} } ],
                        user_id    => $user_id
                    );
                }
                if ( exists $without_region->{dates} ) {
                    $data->upsert(
                        indicators => [
                            $data->indicators_from_variables(
                                variables =>
                                  [ keys %{ $without_region->{variables} } ]
                            )
                        ],
                        dates   => [ keys %{ $without_region->{dates} } ],
                        user_id => $user_id
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

sub _verify_variable_type {
    my ( $self, $value, $type ) = @_;

    return $value if $type eq 'str';

    # certo, entao agora o type é int ou num.

    # vamos tratar o caso mais comum, que é [0-9]{1,3}\.[0-9]{1,3},[0-9]
    if ( $value =~ /[0-9]{1,3}\.[0-9]{1,3},[0-9]{1,9}$/ ) {
        $value =~ s/\.//g;
        $value =~ s/,/./;
    }

    # valores só com virgula.. eh . no banco..
    elsif ( $value =~ /^[0-9]{1,15},[0-9]{1,9}$/ ) {

        $value =~ s/,/./;
    }

    # e agora o inverso... usou , e depois um .
    elsif ( $value =~ /[0-9]{1,3}\,[0-9]{1,3}.[0-9]{1,9}$/ ) {
        $value =~ s/,//g;
        $value =~ s/\./,/;
    }

    # se parece com numero ?
    if ( $value =~ /^[0-9]{1,15}\.[0-9]{1,9}$/ || $value =~ /^[0-9]{1,15}$/ ) {

        $value = int($value) if $type eq 'int';

        return $value;
    }

    # retorna undef.
    undef();
}

1;
