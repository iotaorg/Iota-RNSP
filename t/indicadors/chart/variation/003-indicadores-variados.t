use JSON qw(from_json);
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../../lib";

use Catalyst::Test q(RNSP::PCS);

use HTTP::Request::Common qw/DELETE GET POST/;
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
            my $var1 = &new_var('int', 'yearly');

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
            for my $var (@variacoes){
               my $info = &_get(200, '/api/indicator/'.$ind->{id}.'/variation/'.$var->{id});

               &_post(202, '/api/indicator/'.$ind->{id}.'/variation/'.$var->{id},
                  [   api_key                            => 'test',
                  'indicator.variation.update.name'  => $info->{name} . '.'
               ]);
            }
            my $list = &_get(200, '/api/indicator/'.$ind->{id}.'/variation');
            is(@{$list->{variations}}, 3, 'total match');
            is(substr($_->{name}, -1), '.', 'update ok') for @{$list->{variables_variations}};

            my @subvar = ();

            push @subvar, &_post(201, '/api/indicator/'.$ind->{id}.'/variables_variation',
                [   api_key                            => 'test',
                    'indicator.variables_variation.create.name'  => 'Pessoas'
                ]
            );

            push @subvar, &_post(201, '/api/indicator/'.$ind->{id}.'/variables_variation',
                [   api_key                            => 'test',
                    'indicator.variables_variation.create.name'  => 'variavel para teste'
                ]
            );
            for my $var (@subvar){
               my $info = &_get(200, '/api/indicator/'.$ind->{id}.'/variables_variation/'.$var->{id});

               &_post(202, '/api/indicator/'.$ind->{id}.'/variables_variation/'.$var->{id},
                  [   api_key                            => 'test',
                  'indicator.variables_variation.update.name'  => $info->{name} . '.'
               ]);
            }
            my $list_var = &_get(200, '/api/indicator/'.$ind->{id}.'/variables_variation');
            is(@{$list_var->{variables_variations}}, 2, 'total match');
            is(substr($_->{name}, -1), '.', 'update ok') for @{$list_var->{variables_variations}};


            my @subvals;

            push @subvals, &_post(201, '/api/indicator/'.$ind->{id}.'/variables_variation/'.$subvar[0]{id}.'/values',
                [   api_key                            => 'test',
                    'indicator.variation_value.create.value'  => '5',
                    'indicator.variation_value.create.value_of_date'  => '2010-01-01'
                ]
            );
            for my $val (@subvals){
               my $info = &_get(200, '/api/indicator/'.$ind->{id}.'/variables_variation/'.$subvar[0]{id}.'/values/'.$val->{id});

               &_post(202, '/api/indicator/'.$ind->{id}.'/variables_variation/'.$subvar[0]{id}.'/values/'.$val->{id},
                  [   api_key                            => 'test',
                  'indicator.variation_value.update.value'  => $info->{value} + 1
               ]);
            }
            my $list_val = &_get(200, '/api/indicator/'.$ind->{id}.'/variables_variation/'.$subvar[0]{id}.'/values');

            is(@{$list_val->{'values'}}, 1, 'total match');
            is($list_val->{'values'}[0]{value}, '6', 'value match');


            for my $var (@subvar){

                  my $list_val = &_get(200, '/api/indicator/'.$ind->{id}.'/variables_variation/'.$var->{id}.'/values');

                  &_delete(204, '/api/indicator/'.$ind->{id}.'/variables_variation/'.$var->{id}.'/values/'.$_->{id})
                     for @{$list_val->{values}};
            }

            for my $var (@variacoes){
               &_delete(204, '/api/indicator/'.$ind->{id}.'/variation/'.$var->{id});
               &_delete(410, '/api/indicator/'.$ind->{id}.'/variation/'.$var->{id});
            }

            for my $var (@subvar){
               &_delete(204, '/api/indicator/'.$ind->{id}.'/variables_variation/'.$var->{id});
               &_delete(410, '/api/indicator/'.$ind->{id}.'/variables_variation/'.$var->{id});
            }

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
   if(is( $res->code, $code, 'POST '.$url.' code is ' . $code )){
      my $obj = eval{from_json( $res->content )};
      fail("JSON $url => $@") if $@;
      ok( $obj->{id}, 'POST '.$url.' has id - ID=' . ($obj->{id}||''));
      return $obj;
   }
   return undef;
}


sub _get {
   my ($code, $url, $arr) = @_;
   my ( $res, $c ) = eval{ctx_request(
      GET $url
   )};
   fail("POST $url => $@") if $@;
   if ($code == 0 || is( $res->code, $code, 'GET '.$url.' code is ' . $code )){
      my $obj = eval{from_json( $res->content )};
      fail("JSON $url => $@") if $@;
      return $obj;
   }
   return undef;
}


sub _delete {
   my ($code, $url, $arr) = @_;
   my ( $res, $c ) = eval{ctx_request(
      DELETE $url
   )};
   fail("POST $url => $@") if $@;

   if ($code == 0 || is( $res->code, $code, 'DELETE '.$url.' code is ' . $code )){
      if ($code == 204) {
         is($res->content, '', 'empty body');
      }else{
         my $obj = eval{from_json( $res->content )};
         fail("JSON $url => $@") if $@;
         return $obj;
      }
   }
   return undef;
}

