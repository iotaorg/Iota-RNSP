package Iota::TraitFor::Controller::Search;

use Moose::Role;
with 'Catalyst::TraitFor::Controller::DBIC::DoesPaging';

# a jquery manda essa _ pra nao fazer cache
has 'ignored_params' => (
    is      => 'rw',
    default => sub {
        [
            qw(password api_key columns content-type _ limit start sort dir _dc rm xaction indicator_id network_id role with_polygon_path config_user_id user_id)
        ];
    }
);

my $ignored_params_cache;

around list_GET => sub {
    my $orig = shift;
    my $self = shift;
    my ($c)  = @_;

    my @columns = defined $c->req->params->{columns} ? split /,/, $c->req->params->{columns} : ();

    my $qtde_param = 0;

    if ( !$ignored_params_cache ) {
        foreach my $ig ( @{ $self->ignored_params } ) {
            $ignored_params_cache->{$ig} = 1;
        }
    }

    foreach my $k ( keys %{ $c->request->params } ) {
        $qtde_param++ unless $ignored_params_cache->{$k};
    }

    # essa search aqui embaixo remove os parametros -.-'
    if ( $qtde_param > 0 && !@columns ) {
        $c->stash->{collection} = $self->search( $c, $c->stash->{collection} );
    }

    # apenas habilite o header se for testes entre diferentes sites
    # $c->res->header('Access-Control-Allow-Origin' => '*');

    $self->$orig(@_);
    if ( @columns && !$c->stash->{rest}{error} ) {

        # start: pra nao precisar alterar os controllers hj,
        # vamos pegar a primeira chave (porque geralmente só tem uma, e
        # assumir que é a array

        my ($key) = keys %{ $c->stash->{rest} };
        my @aaData = ();

        foreach my $data ( @{ $c->stash->{rest}{$key} } ) {
            my @row = ();
            foreach my $colNm (@columns) {
                if ( $colNm =~ /\./o ) {
                    my @subkeys = split /\./o, $colNm;
                    my $f = shift @subkeys;

                    my $ref = eval { $data->{$f} };
                    $ref = eval { $ref->{$_} } for (@subkeys);

                    push @row, $ref;
                }
                else {
                    if ( $colNm eq '_' ) { push @row, undef; next }
                    push @row, $data->{$colNm};
                }
            }
            push @aaData, \@row;
        }
        $c->stash->{rest} = { aaData => \@aaData };

    }

};

1;

