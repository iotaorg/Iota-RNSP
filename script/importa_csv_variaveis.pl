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
my $user   = Iota::TestOnly::Mock::AuthUser->new;

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

            name        => qr/\bnome\b/,
            explanation => qr/explanation/,
            cognomen    => qr/cognomen/,
            type        => qr/type/,
            period      => qr/period/,

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

                if (
                       exists $registro->{name}
                    && exists $registro->{explanation}
                    && exists $registro->{cognomen}
                    && exists $registro->{type}
                    && exists $registro->{period}

                  ) {

                    $registro->{period} =~ s/anual/yearly/;
                    $registro->{period} =~ s/mensal/monthly/;

                    $registro->{type} =~ s/inteiro/int/;
                    $registro->{type} =~ s/valor/num/;

                    $registro->{cognomen} =~ s/-/_/g;

                    next if exists $ig->{ $registro->{cognomen} };
                    $ig->{ $registro->{cognomen} }++;

                    my ( $res, $c );
                    ( $res, $c ) = ctx_request(
                        POST '/api/variable',
                        [
                            api_key                       => 'test',
                            'variable.create.name'        => $registro->{name},
                            'variable.create.cognomen'    => $registro->{cognomen},
                            'variable.create.explanation' => $registro->{explanation},
                            'variable.create.type'        => $registro->{type},
                            'variable.create.period'      => $registro->{period},

                        ]
                    );
                    my $obj = eval { decode_json( $res->content ) };

                    die Dumper {
                        err     => Dumper $obj,
                          value => $registro;
                    }
                    unless $res->is_success;

                    $registro->{id} = $obj;

                    push @rows, $registro;

                }
                else {
                    use DDP;
                    p @data;
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
