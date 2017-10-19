package Iota::Test::Further;
use common::sense;
use FindBin qw($RealBin);
use Carp;

use Test::More;
use Catalyst::Test q(Iota);
use CatalystX::Eta::Test::REST;

use HTTP::Request::Common;
use Data::Printer;
use JSON::MaybeXS;

my $seq = 0;

# ugly hack
sub import {
    strict->import;
    warnings->import;

    no strict 'refs';

    my $caller = caller;

    while ( my ( $name, $symbol ) = each %{ __PACKAGE__ . '::' } ) {
        next if $name eq 'BEGIN';     # don't export BEGIN blocks
        next if $name eq 'import';    # don't export this sub
        next unless *{$symbol}{CODE}; # export subs only

        my $imported = $caller . '::' . $name;
        *{$imported} = \*{$symbol};
    }
}

my $obj = CatalystX::Eta::Test::REST->new(
    do_request => sub {
        my $req = shift;

        eval 'do{my $x = $req->as_string; p $x}'
          if exists $ENV{TRACE} && $ENV{TRACE};
        my ( $res, $c ) = ctx_request($req);
        eval 'do{my $x = $res->as_string; p $x}'
          if exists $ENV{TRACE} && $ENV{TRACE};
        return $res;
    },
    decode_response => sub {
        my $res = shift;
        return decode_json( $res->content );
    }
);

for (qw/rest_get rest_put rest_head rest_delete rest_post rest_reload rest_reload_list/) {

    eval( 'sub ' . $_ . ' { return $obj->' . $_ . '(@_) }' );
}

sub stash_test ($&) {
    $obj->stash_ctx(@_);
}

sub stash ($) {
    $obj->stash->{ $_[0] };
}

sub test_instance { $obj }

sub db_transaction (&) {
    my ( $subref, $modelname ) = @_;

    my $schema = Iota->model( $modelname || 'DB' );

    eval {
        $schema->txn_do(
            sub {
                $subref->($schema);
                die 'rollback';
            }
        );
    };
    die $@ unless $@ =~ /rollback/;
}

sub new_var {
    my $type   = shift;
    my $period = shift;
    my $res2;
    my $c;
    ( $res2, $c ) = ctx_request(
        POST '/api/variable',
        [
            api_key                       => 'test',
            'variable.create.name'        => 'Foo Bar' . $seq++,
            'variable.create.cognomen'    => 'foobar' . $seq++,
            'variable.create.explanation' => 'a foo with bar' . $seq++,
            'variable.create.type'        => $type,
            'variable.create.period'      => $period || 'week',
            'variable.create.source'      => 'God',
        ]
    );
    if ( $res2->code == 201 ) {
        my $xx = decode_json( $res2->content );
        return $xx->{id};
    }
    else {
        die( 'fail to create new var: ' . $res2->code );
    }
}
 
1;
