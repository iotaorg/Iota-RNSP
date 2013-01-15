use JSON qw(from_json);
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../../lib";

use Catalyst::Test q(RNSP::PCS);

use HTTP::Request::Common;
use Package::Stash;

use RNSP::PCS::TestOnly::Mock::AuthUser;

my $schema = RNSP::PCS->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = RNSP::PCS::TestOnly::Mock::AuthUser->new;

$RNSP::PCS::TestOnly::Mock::AuthUser::_id    = 1;
@RNSP::PCS::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );
my $seq = 0;
eval {
    $schema->txn_do(
        sub {
            my $var1 = &new_var('int', 'weekly');

            my $ind = &_post(201, '/api/indicator',
                [   api_key                         => 'test',
                    'indicator.create.name'         => 'Distribuição de renda',
                    'indicator.create.formula'      => '#1 + #2 + $' . $var1,
                    'indicator.create.axis_id'      => '1',
                    'indicator.create.explanation'  => 'Distribuição por faixas de renda (pessoas de 10 anos ou mais de idade).',
                    'indicator.create.source'       => 'Rede Nossa São Paulo',
                    'indicator.create.goal_source'  => 'Diminuir as distâncias entre as faixas de renda da população.',
                    'indicator.create.chart_name'   => 'pie',
                    'indicator.create.goal_operator'=> '>=',
                    'indicator.create.tags'         => 'you,me,she',
                    'indicator.create.observations' => 'lala',
                    'indicator.create.variety_name'   => 'Faixas',
                    'indicator.create.indicator_type' => 'varied',

                ]
            );

            my @variacoes = ();

            push @variacoes, &_post(201, '/api/indicator/'.$ind->{id}.'/variation',
                [   api_key                            => 'test',
                    'indicator.variation.create.name'  => 'Até 1/2 salário mínimo'
                ]
            );

            push @variacoes, &_post(201, '/api/indicator/'.$ind->{id}.'/variation',
                [   api_key                            => 'test',
                    'indicator.variation.create.name'  => 'Mais de 1/2 a 1 salário mínimo'
                ]
            );

            push @variacoes, &_post(201, '/api/indicator/'.$ind->{id}.'/variation',
                [   api_key                            => 'test',
                    'indicator.variation.create.name'  => 'Mais de 1 a 2 salários mínimos'
                ]
            );
            my $list = &_get(200, '/api/indicator/'.$ind->{id}.'/variation');
            is(@{$list->{variations}}, 3, 'total match');
            for my $var (@variacoes){
               my $info = &_get(200, '/api/indicator/'.$ind->{id}.'/variation/'.$var->{id});

               &_post(202, '/api/indicator/'.$ind->{id}.'/variation/'.$var->{id},
                  [   api_key                            => 'test',
                  'indicator.variation.update.name'  => $info->{name} . '.'
               ]);
            }


            use DDP; p @variacoes;

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;


use JSON qw(from_json);
sub new_var {
    my $type = shift;
    my $period = shift;
    my ( $res, $c ) = ctx_request(
        POST '/api/variable',
        [   api_key                        => 'test',
            'variable.create.name'         => 'Foo Bar'.$seq++,
            'variable.create.cognomen'     => 'foobar'.$seq++,
            'variable.create.explanation'  => 'a foo with bar'.$seq++,
            'variable.create.type'         => $type,
            'variable.create.period'       => $period||'week',
            'variable.create.source'       => 'God',
        ]
    );
    if ($res->code == 201){
        my $xx = eval{from_json( $res->content )};
        return $xx->{id};
    }else{
        die('fail to create new var: ' . $res->code);
    }
}

sub _post {
   my ($code, $url, $arr) = @_;
   my ( $res, $c ) = eval{ctx_request(
      POST $url, $arr
   )};
   fail("POST $url => $@") if $@;
   is( $res->code, $code, 'POST '.$url.' code is ' . $code );

   my $obj = eval{from_json( $res->content )};
   fail("JSON $url => $@") if $@;
   ok( $obj->{id}, 'POST '.$url.' has id - ID=' . ($obj->{id}||''));
   return $obj;
}


sub _get {
   my ($code, $url, $arr) = @_;
   my ( $res, $c ) = eval{ctx_request(
      GET $url
   )};
   fail("POST $url => $@") if $@;
   is( $res->code, $code, 'GET '.$url.' code is ' . $code );

   my $obj = eval{from_json( $res->content )};
   fail("JSON $url => $@") if $@;
   return $obj;
}


sub _delete {
   my ($code, $url, $arr) = @_;
   my ( $res, $c ) = eval{ctx_request(
      DELETE $url
   )};
   fail("POST $url => $@") if $@;
   is( $res->code, $code, 'DELETE '.$url.' code is ' . $code );

   my $obj = eval{from_json( $res->content )};
   fail("JSON $url => $@") if $@;
   return $obj;
}

