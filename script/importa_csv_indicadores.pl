use strict;
use utf8;
use DateTime;
use DateTime::Format::Pg;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Data::Dumper;
use JSON::XS;
use Text::CSV_XS;

use Catalyst::Test q(Iota);

use HTTP::Request::Common;
use Package::Stash;

use Iota::TestOnly::Mock::AuthUser;

my $schema = Iota->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
use DDP;
my $user = Iota::TestOnly::Mock::AuthUser->new;
$Iota::TestOnly::Mock::AuthUser::_id    = 1;
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

$schema->txn_do(
    sub {

        my $file = $ARGV[0];

        my $csv = Text::CSV_XS->new( { binary => 1 } )
          or die "Cannot use CSV: " . Text::CSV_XS->error_diag();
        open my $fh, "<:encoding(utf8)", $file or die "$file: $!";

        my %expected_header = (
            name             => qr/\bname\b/,
            formula          => qr/formula\b/,
            axis_id          => qr/axis_id\b/,
            explanation      => qr/explanation\b/,
            goal             => qr/goal\b/,
            goal_explanation => qr/goal_explanation\b/,
            goal_source      => qr/goal_source\b/,
            source           => qr/source\b/,

            goal_operator  => qr/goal_operator\b/,
            observations   => qr/observations\b/,
            sort_direction => qr/sort_direction\b/,
            visibility_networks_id => qr/visibility_networks_id/

        );

        my @rows;
        my $ok      = 0;
        my $ignored = 0;

        my $header_map   = {};
        my $header_found = 0;

        my $ig = {};

        while ( my $row = $csv->getline($fh) ) {

            my @data = @$row;

            if ( !$header_found ) {

                for my $col ( 0 .. ( scalar @data - 1 ) ) {
                    my $cell = $data[$col];
                    next unless $cell;

                    foreach my $header_name ( keys %expected_header ) {

                        if ( $cell =~ $expected_header{$header_name} ) {
                            $header_found++;
                            $header_map->{$header_name} = $col;
                        }
                    }
                }
                p $header_map;
            }
            else {

# aqui você pode verificar se foram encontrados todos os campos que você precisa
# neste caso, achar apenas 1 cabeçalho já é o suficiente

                my $registro = {};

                foreach my $header_name ( keys %$header_map ) {
                    my $col = $header_map->{$header_name};

                    my $value = $data[$col];

# aqui é uma regra que você escolhe, pois as vezes o valor da célula pode ser nulo
                    next if !defined $value || $value =~ /^\s*$/;
                    $value =~ s/^\s+//;
                    $value =~ s/\s+$//;
                    $registro->{$header_name} = $value;
                }
                p $registro;
                if (
                       exists $registro->{name}
                    && exists $registro->{formula}

                  )
                {

                    $registro->{formula} =~ s/\s+/ /g;
                    $registro->{formula} =~ s/\$\s+(\d)/\$$1/g;

                    my $err = eval {
                        Iota::IndicatorFormula->new(
                            formula => $registro->{formula},
                            schema  => $schema
                        );
                    };

                    $registro->{formula} = 'CONCATENAR' . $registro->{formula}
                      if $@ && $@ =~ /is a str and/;
                    my ( $obj, $res, $c );
                  RTY:
                    ( $res, $c ) = ctx_request(
                        POST '/api/indicator',
                        [
                            api_key                    => 'test',
                            'indicator.create.axis_id' => $registro->{axis_id},
                            'indicator.create.name'    => $registro->{name},
                            'indicator.create.formula' => $registro->{formula},
                            'indicator.create.observations' =>
                              $registro->{observations},
                            'indicator.create.explanation' =>
                              $registro->{explanation},
                            'indicator.create.goal' => $registro->{goal},
                            'indicator.create.goal_explanation' =>
                              $registro->{goal_explanation},
                            'indicator.create.goal_source' =>
                              $registro->{goal_source},
                            'indicator.create.source' => $registro->{source},
                            'indicator.create.sort_direction' =>
                              $registro->{sort_direction},

                            'indicator.create.visibility_level' => 'network',
                            'indicator.create.visibility_networks_id' => $registro->{visibility_networks_id},
                        ]
                    );

                    $obj = eval { decode_json( $res->content ) };
                    use DDP;
                    p $obj;
                    if ( $res->content =~ /name/ && $res->content =~ /invalid/ )
                    {
                        $registro->{name} .= ' 2';
                        goto RTY;
                    }
                    else {
                        die $@ if $@;
                    }
                    die Dumper {
                        err   => Dumper $obj,
                        value => $registro,
                        err   => $@
                      }
                      unless $res->is_success;

                    $registro->{id} = $obj;

                    push @rows, $registro;

                }
                else {
                    use DDP;
                    p \@data;
                    p $registro;
                    $ignored++;
                }

            }
        }
        $csv->eof or $csv->error_diag();
        close $fh;
        use DDP;
        p $ignored;
        use DDP;
        p @rows;

    }
);
