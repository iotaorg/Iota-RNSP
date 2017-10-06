package Iota::Controller::API::CompareByRegion;
use Moose;
BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

use utf8;

use JSON::XS;
use Encode qw(encode);

sub do : Chained('/light_institute_load') : PathPart('api/public/compare-by-region') : Args(0) : ActionClass('REST') {
}

sub do_GET {
    my ( $self, $c ) = @_;

    my $city_id = $c->req->params->{city_id};
    $self->error( $c, 'invalid city_id' ) unless $city_id =~ /^[0-9]+$/;

    my $indicators = $c->req->params->{indicators};
    $self->error( $c, 'invalid indicators' ) unless $indicators =~ /^([0-9]+:[A-Z0-9]+\s?)+$/i;
    $indicators =~ s/ $//;

    my $periods = $c->req->params->{periods};
    $self->error( $c, 'invalid periods' ) unless $periods =~ /^([0-9]{4}-[0-9]{2}-[0-9]{2},?)+$/;
    $indicators =~ s/,$//;

    my $user_id = $c->model('DB::User')->search(
        {
            city_id      => $city_id,
            institute_id => $c->stash->{institute}->id
        }
    )->get_column('id')->next;
    $self->error( $c, 'missing user' ) unless $user_id;

    $indicators = { map { split /:/ } split / /, $indicators };
    my $indicators_apels = { %{$indicators} };
    $periods = [ split /,/, $periods ];

    my @shapes = $c->model('DB::Region')->search(
        {
            'me.city_id'      => $city_id,
            'me.polygon_path' => { '!=' => undef },
            'me.depth_level'  => 3,
        },
        {
            join         => 'upper_region',
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            columns      => [ 'id', 'name', 'polygon_path', 'upper_region.name' ],
            order_by     => 'me.name',
        }
    )->all;

    my @indicators_in_order = $c->model('DB::Indicator')->search(
        {
            id            => { 'in' => [ keys %$indicators ] },
            variable_type => { 'in' => [qw/int num/] }
        },
        {

            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            columns      => [ 'id', 'name', 'sort_direction' ],
            order_by     => 'name'
        }
    )->all;
    $indicators = { map { $_->{id} => $_ } @indicators_in_order };

    my @values = $c->model('DB::IndicatorValue')->search(
        {
            user_id        => $user_id,
            valid_from     => { 'in' => $periods },
            indicator_id   => { 'in' => [ keys %$indicators ] },
            region_id      => { 'in' => [ map { $_->{id} } @shapes ] },
            variation_name => '',
        },
        {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            columns      => [ qw/indicator_id valid_from variation_name region_id/, { num => \'me.value::numeric' } ]
        }
    )->all;

    my $values_ref = {};

    # reduzindo quantidade de redudancia no json
    for (@values) {
        $values_ref->{ delete $_->{indicator_id} }{ delete $_->{valid_from} }{ delete $_->{variation_name} }
          { $_->{region_id} } = $_;
    }

    my $freq = Iota::Statistics::Frequency->new();

    my $sup = {};
    while ( my ( $id_id, $por_ano ) = each %$values_ref ) {

        my $out = {};
        while ( my ( $ano, $variacoes ) = each %$por_ano ) {
            while ( my ( $variacao, $regions_list ) = each %$variacoes ) {

                my $indicator = $indicators->{$id_id};

                my $regions = [ map { $regions_list->{$_} } keys %$regions_list ];

                my $stat = $freq->iterate($regions);

                my $defined_regions = [ grep { defined $_->{num} } @$regions ];

                # melhor = mais alto, entao inverte as cores
                if (  !$indicator->{sort_direction}
                    || $indicator->{sort_direction} eq 'greater value' ) {
                    $_->{i} = 4 - $_->{i} for @$defined_regions;
                    $regions =
                      [ ( reverse grep { defined $_->{num} } @$regions ), grep { !defined $_->{num} } @$regions ];
                    $defined_regions = [ reverse @$defined_regions ];
                }

                if ($stat) {
                    $out->{$ano}{$variacao} = { all => $regions, };
                }
                elsif ( @$defined_regions == 4 ) {
                    $defined_regions->[0]{i} = 0;    # Alta / Melhor
                    $defined_regions->[1]{i} = 1;    # acima media
                    $defined_regions->[2]{i} = 3;    # abaixo da media
                    $defined_regions->[3]{i} = 4;    # Baixa / Pior
                }
                elsif ( @$defined_regions == 3 ) {
                    $defined_regions->[0]{i} = 0;    # Alta / Melhor
                    $defined_regions->[1]{i} = 2;    # média
                    $defined_regions->[2]{i} = 4;    # Baixa / Pior
                }
                elsif ( @$defined_regions == 2 ) {
                    $defined_regions->[0]{i} = 0;    # Alta / Melhor
                    $defined_regions->[1]{i} = 4;    # Baixa / Pior
                }
                else {
                    $_->{i} = 5 for @$defined_regions;
                }

                $out->{$ano}{$variacao} = { all => $regions }
                  unless exists $out->{$ano}{$variacao};

            }
        }

        $sup->{$id_id} = $out;
    }

    my $rotated = {};
    my %variations;

    sub fmt_year {
        my $y = shift;
        $y =~ s/-.+$//o;
        $y;
    }

    while ( my ( $indicator_id, $by_year ) = each %$sup ) {

        while ( my ( $year, $variations ) = each %$by_year ) {
            while ( my ( $variation, $regions_list ) = each %$variations ) {

                $variations{$variation} = 1 unless exists $variations{$variation};

                foreach ( @{ $regions_list->{all} } ) {
                    $_->{rnum} = Iota::View::HTML::value4human( undef, $c, $_->{num}, 'num' );

                    $rotated->{$variation}{ delete $_->{region_id} }{ fmt_year($year) }{$indicator_id} = $_;
                }
            }
        }
    }

    $self->status_ok(
        $c,
        entity => {
            values           => $rotated,
            regions          => { map { $_->{id} => $_ } @shapes },
            indicators       => $indicators,
            variations       => [ keys %variations ],
            indicators_apels => $indicators_apels,

            indicators_in_order => [ map { $_->{id} } @indicators_in_order ],
            regions_in_order    => [ map { $_->{id} } @shapes ],

        }
    );
}

sub error : Private {
    my ( $self, $c, $msg ) = @_;

    $self->status_bad_request( $c, message => $msg );
    $c->detach;
}

1;
