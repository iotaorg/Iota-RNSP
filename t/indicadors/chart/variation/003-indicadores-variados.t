use JSON qw(from_json);
use strict;
use warnings;
use URI;
use Test::More;

use utf8;
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
my $indicator;
eval {
   $schema->txn_do(
      sub {
            my ( $var1, $uri1 ) = &new_var( 'int', 'yearly' );

            $indicator = &_post(
               201,
               '/api/indicator',
               [
                  api_key                    => 'test',
                  'indicator.create.name'    => 'Distribuição de renda',
                  'indicator.create.formula' => '#1 + #2 + $' . $var1,
                  'indicator.create.axis_id' => '1',
                  'indicator.create.explanation' =>
                     'Distribuição por faixas de renda (pessoas de 10 anos ou mais de idade).',
                  'indicator.create.source' => 'Rede Nossa São Paulo',
                  'indicator.create.goal_source' =>
                     'Diminuir as distâncias entre as faixas de renda da população.',
                  'indicator.create.chart_name'     => 'pie',
                  'indicator.create.goal_operator'  => '>=',
                  'indicator.create.tags'           => 'you,me,she',
                  'indicator.create.observations'   => 'lala',
                  'indicator.create.variety_name'   => 'Faixas',
                  'indicator.create.indicator_type' => 'varied',
                  'indicator.create.indicator_roles' => '_prefeitura,_movimento'
               ]
            );

            my @variacoes = ();

            push @variacoes,
            &_post(
               201,
               '/api/indicator/' . $indicator->{id} . '/variation',
               [
                  api_key                            => 'test',
                  'indicator.variation.create.name'  => 'Até 1/2 salário mínimo',
                  'indicator.variation.create.order' => '2',
               ]
            );

            push @variacoes,
            &_post(
               201,
               '/api/indicator/' . $indicator->{id} . '/variation',
               [
                  api_key                            => 'test',
                  'indicator.variation.create.name'  => 'Mais de 1/2 a 1 salário mínimo',
                  'indicator.variation.create.order' => '3',
               ]
            );

            push @variacoes,
            &_post(
               201,
               '/api/indicator/' . $indicator->{id} . '/variation',
               [
                  api_key                            => 'test',
                  'indicator.variation.create.name'  => 'Mais de 1 a 2 salários mínimos',
                  'indicator.variation.create.order' => '4',
               ]
            );

            push @variacoes,
            &_post(
               201,
               '/api/indicator/' . $indicator->{id} . '/variation',
               [
                  api_key                            => 'test',
                  'indicator.variation.create.name'  => 'outros',
                  'indicator.variation.create.order' => '5',
               ]
            );
            for my $var (@variacoes) {
               my $info = &_get( 200, '/api/indicator/' . $indicator->{id} . '/variation/' . $var->{id} );

               &_post(
                  202,
                  '/api/indicator/' . $indicator->{id} . '/variation/' . $var->{id},
                  [
                        api_key                           => 'test',
                        'indicator.variation.update.name' => $info->{name} . '.'
                  ]
               );
            }
            my $list = &_get( 200, '/api/indicator/' . $indicator->{id} . '/variation' );
            is( @{ $list->{variations} }, 4, 'total match' );
            is( substr( $_->{name}, -1 ), '.', 'update ok' ) for @{ $list->{variables_variations} };

            my @subvar = ();

            push @subvar,
            &_post(
               201,
               '/api/indicator/' . $indicator->{id} . '/variables_variation',
               [
                  api_key                                     => 'test',
                  'indicator.variables_variation.create.name' => 'Pessoas'
               ]
            );

            push @subvar,
            &_post(
               201,
               '/api/indicator/' . $indicator->{id} . '/variables_variation',
               [
                  api_key                                     => 'test',
                  'indicator.variables_variation.create.name' => 'variavel para teste',
               ]
            );

            my $list_variables = &_get(200,'/api/indicator/variable');
            is(@{$list_variables->{variables}}, 2, 'count of /api/indicator/variable looks fine');

            # -----------
            ## DEADLOCK do formula faz com que a gente tenha que atualizar a formula com os IDs
            # -----------
            my $res = &_post(
               202,
               '/api/indicator/' . $indicator->{id},
               [
                  api_key => 'test',

                  'indicator.update.formula' => '#' . $subvar[0]{id} . ' + #' . $subvar[1]{id} . ' + $' . $var1,
               ]
            );
            for my $var (@subvar) {
               my $info = &_get( 200, '/api/indicator/' . $indicator->{id} . '/variables_variation/' . $var->{id} );

               &_post(
                  202,
                  '/api/indicator/' . $indicator->{id} . '/variables_variation/' . $var->{id},
                  [
                        api_key                                     => 'test',
                        'indicator.variables_variation.update.name' => $info->{name} . '.'
                  ]
               );
            }
            my $list_var = &_get( 200, '/api/indicator/' . $indicator->{id} . '/variables_variation' );
            is( @{ $list_var->{variables_variations} }, 2, 'total match' );
            is( substr( $_->{name}, -1 ), '.', 'update ok' ) for @{ $list_var->{variables_variations} };


            my $detalhes = &_get( 200, '/api/indicator/' . $indicator->{id} );
            is(@{$detalhes->{variables}},2,'detalhes de variaveis ok');
            is(@{$detalhes->{variations}},4,'detalhes de variacoes ok');


            my @subvals;

            push @subvals,
            &_post(
               201,
               '/api/indicator/' . $indicator->{id} . '/variables_variation/' . $subvar[0]{id} . '/values',
               [
                  api_key                                                   => 'test',
                  'indicator.variation_value.create.value'                  => '5',
                  'indicator.variation_value.create.indicator_variation_id' => $variacoes[0]{id},
                  'indicator.variation_value.create.value_of_date'          => '2010-01-01'
               ]
            );
            for my $val (@subvals) {
               my $info = &_get( 200,
                        '/api/indicator/'
                     . $indicator->{id}
                     . '/variables_variation/'
                     . $subvar[0]{id}
                     . '/values/'
                     . $val->{id} );
               &_post(
                  202,
                  '/api/indicator/'
                     . $indicator->{id}
                     . '/variables_variation/'
                     . $subvar[0]{id}
                     . '/values/'
                     . $val->{id},
                  [
                        api_key                                  => 'test',
                        'indicator.variation_value.update.value' => $info->{value} + 1
                  ]
               );
            }
            my $list_val =
            &_get( 200, '/api/indicator/' . $indicator->{id} . '/variables_variation/' . $subvar[0]{id} . '/values' );

            is( @{ $list_val->{'values'} },      1,   'total match' );
            is( $list_val->{'values'}[0]{value}, '6', 'value match' );
            &_delete( 204,
                  '/api/indicator/'
                  . $indicator->{id}
                  . '/variables_variation/'
                  . $subvar[0]{id}
                  . '/values/'
                  . $list_val->{'values'}[0]{id} );

            # Pessoas
            &_populate( $subvar[0]{id}, \@variacoes, '2010-01-01', qw/3 5 6 10/ );
            &_populate( $subvar[0]{id}, \@variacoes, '2011-01-01', qw/4 4 1 5/ );
            &_populate( $subvar[0]{id}, \@variacoes, '2012-01-01', qw/5 4 6 8/ );
            &_populate( $subvar[0]{id}, \@variacoes, '2013-01-01', qw/4 4 7 9/ );

            # fixo
            &_populate( $subvar[1]{id}, \@variacoes, '2010-01-01', qw/1 1 1 1/ );
            &_populate( $subvar[1]{id}, \@variacoes, '2011-01-01', qw/1 1 1 1/ );
            &_populate( $subvar[1]{id}, \@variacoes, '2012-01-01', qw/1 1 1 1/ );
            &_populate( $subvar[1]{id}, \@variacoes, '2013-01-01', qw/1 1 1 1/ );

            &add_value( $uri1, '2010-01-01', 15 );
            &add_value( $uri1, '2011-01-01', 16 );
            &add_value( $uri1, '2012-01-01', 17 );
            &add_value( $uri1, '2013-01-01', 18 );


            my $period = &_get( 200, '/api/indicator/' . $indicator->{id} . '/variables_variation/'.$subvar[0]{id}.'/values?valid_from=2012-01-01');
            is(@{$period->{values}}, 4, 'filtro aplicado corretamente');



            # testando historico
            my $res_variable_value = &_get( 200, '/api/indicator/' . $indicator->{id} . '/variable/value' );

            my $expe = {
               'rows' => [
                  {
                        'formula_value' => 88,
                        'valores'       => [
                           {
                              'variable_id'   => $var1,
                              'source'        => undef,
                              'value'         => '15',
                              'value_of_date' => '2010-01-01T00:00:00',
                              'observations'  => undef,
                           }
                        ],
                        'variations' => [
                           {
                              'value' => 19,

                              'name' =>
"At\x{c3}\x{83}\x{c2}\x{a9} 1/2 sal\x{c3}\x{83}\x{c2}\x{a1}rio m\x{c3}\x{83}\x{c2}\x{ad}nimo."
                           },
                           {

                              'value' => 21,

                              'name' =>
                                 "Mais de 1/2 a 1 sal\x{c3}\x{83}\x{c2}\x{a1}rio m\x{c3}\x{83}\x{c2}\x{ad}nimo."
                           },
                           {

                              'value' => 22,

                              'name' =>
                                 "Mais de 1 a 2 sal\x{c3}\x{83}\x{c2}\x{a1}rios m\x{c3}\x{83}\x{c2}\x{ad}nimos."
                           },
                           {

                              'value' => 26,

                              'name' => 'outros.'
                           }
                        ],
                        'valid_from' => '2010-01-01T00:00:00'
                  },
                  {
                        'formula_value' => 82,
                        'valores'       => [
                           {
                              'variable_id'   => $var1,
                              'source'        => undef,
                              'value'         => '16',
                              'value_of_date' => '2011-01-01T00:00:00',
                              'observations'  => undef,
                           }
                        ],
                        'variations' => [
                           {

                              'value' => 21,

                              'name' =>
"At\x{c3}\x{83}\x{c2}\x{a9} 1/2 sal\x{c3}\x{83}\x{c2}\x{a1}rio m\x{c3}\x{83}\x{c2}\x{ad}nimo."
                           },
                           {

                              'value' => 21,

                              'name' =>
                                 "Mais de 1/2 a 1 sal\x{c3}\x{83}\x{c2}\x{a1}rio m\x{c3}\x{83}\x{c2}\x{ad}nimo."
                           },
                           {

                              'value' => 18,

                              'name' =>
                                 "Mais de 1 a 2 sal\x{c3}\x{83}\x{c2}\x{a1}rios m\x{c3}\x{83}\x{c2}\x{ad}nimos."
                           },
                           {

                              'value' => 22,

                              'name' => 'outros.'
                           }
                        ],
                        'valid_from' => '2011-01-01T00:00:00'
                  },
                  {
                        'formula_value' => 95,
                        'valores'       => [
                           {
                              'variable_id'   => $var1,
                              'source'        => undef,
                              'value'         => '17',
                              'value_of_date' => '2012-01-01T00:00:00',
                              'observations'  => undef,
                           }
                        ],
                        'variations' => [
                           {

                              'value' => 23,

                              'name' =>
"At\x{c3}\x{83}\x{c2}\x{a9} 1/2 sal\x{c3}\x{83}\x{c2}\x{a1}rio m\x{c3}\x{83}\x{c2}\x{ad}nimo."
                           },
                           {

                              'value' => 22,

                              'name' =>
                                 "Mais de 1/2 a 1 sal\x{c3}\x{83}\x{c2}\x{a1}rio m\x{c3}\x{83}\x{c2}\x{ad}nimo."
                           },
                           {

                              'value' => 24,

                              'name' =>
                                 "Mais de 1 a 2 sal\x{c3}\x{83}\x{c2}\x{a1}rios m\x{c3}\x{83}\x{c2}\x{ad}nimos."
                           },
                           {

                              'value' => 26,

                              'name' => 'outros.'
                           }
                        ],
                        'valid_from' => '2012-01-01T00:00:00'
                  },
                  {
                        'formula_value' => 100,
                        'valores'       => [
                           {
                              'variable_id'   => $var1,
                              'source'        => undef,
                              'value'         => '18',
                              'value_of_date' => '2013-01-01T00:00:00',
                              'observations'  => undef,
                           }
                        ],
                        'variations' => [
                           {

                              'value' => 23,

                              'name' =>
"At\x{c3}\x{83}\x{c2}\x{a9} 1/2 sal\x{c3}\x{83}\x{c2}\x{a1}rio m\x{c3}\x{83}\x{c2}\x{ad}nimo."
                           },
                           {

                              'value' => 23,

                              'name' =>
                                 "Mais de 1/2 a 1 sal\x{c3}\x{83}\x{c2}\x{a1}rio m\x{c3}\x{83}\x{c2}\x{ad}nimo."
                           },
                           {

                              'value' => 26,

                              'name' =>
                                 "Mais de 1 a 2 sal\x{c3}\x{83}\x{c2}\x{a1}rios m\x{c3}\x{83}\x{c2}\x{ad}nimos."
                           },
                           {

                              'value' => 28,

                              'name' => 'outros.'
                           }
                        ],
                        'valid_from' => '2013-01-01T00:00:00'
                  }
               ],
               'header' => { 'Foo Bar0' => 0 }
            };
            delete $res_variable_value->{rows}[$_]{valores}[0]{id} for 0 .. 3;
            is_deeply( $res_variable_value, $expe, '/api/indicator/' . $indicator->{id} . '/variable/value dont looks nice..' );

            # testa o cenario menos comum de delete
            # que seria cada endpoint
            # mas na real, geralmente eh um delete no indicador inteiro
            for my $var (@subvar) {

               my $list_val =
                  &_get( 200, '/api/indicator/' . $indicator->{id} . '/variables_variation/' . $var->{id} . '/values' );

               &_delete( 204,
                        '/api/indicator/'
                     . $indicator->{id}
                     . '/variables_variation/'
                     . $var->{id}
                     . '/values/'
                     . $_->{id} )
                  for @{ $list_val->{values} };
            }
            for my $var (@variacoes) {
               &_delete( 204, '/api/indicator/' . $indicator->{id} . '/variation/' . $var->{id} );
               &_delete( 410, '/api/indicator/' . $indicator->{id} . '/variation/' . $var->{id} );
            }

            for my $var (@subvar) {
               &_delete( 204, '/api/indicator/' . $indicator->{id} . '/variables_variation/' . $var->{id} );
               &_delete( 410, '/api/indicator/' . $indicator->{id} . '/variables_variation/' . $var->{id} );
            }

            &_delete( 204, '/api/indicator/' . $indicator->{id} );

            die 'rollback';
      }
   );

};

die $@ unless $@ =~ /rollback/;

done_testing;

use JSON qw(from_json);

sub new_var {
   my $type   = shift;
   my $period = shift;
   my ( $res, $c ) = ctx_request(
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
   if ( $res->code == 201 ) {
      my $xx = eval { from_json( $res->content ) };

      return ( $xx->{id}, URI->new( $res->header('Location') )->as_string );
   }
   else {
      die( 'fail to create new var: ' . $res->code );
   }
}

sub _post {
   my ( $code, $url, $arr ) = @_;
   my ( $res, $c ) = eval { ctx_request( POST $url, $arr ) };
   fail("POST $url => $@") if $@;
   is( $res->code, $code, 'POST ' . $url . ' code is ' . $code );
   my $obj = eval { from_json( $res->content ) };
   fail("JSON $url => $@") if $@;
   ok( $obj->{id}, 'POST ' . $url . ' has id - ID=' . ( $obj->{id} || '' ) );
   return $obj;
}

sub _get {
   my ( $code, $url, $arr ) = @_;
   my ( $res, $c ) = eval { ctx_request( GET $url ) };
   fail("POST $url => $@") if $@;

   if ( $code == 0 || is( $res->code, $code, 'GET ' . $url . ' code is ' . $code ) ) {
      my $obj = eval { from_json( $res->content ) };
      fail("JSON $url => $@") if $@;
      return $obj;
   }
   use DDP; p $res;
   return undef;
}

sub _delete {
   my ( $code, $url, $arr ) = @_;
   my ( $res, $c ) = eval { ctx_request( DELETE $url ) };
   fail("POST $url => $@") if $@;

   if ( $code == 0 || is( $res->code, $code, 'DELETE ' . $url . ' code is ' . $code ) ) {
      if ( $code == 204 ) {
            is( $res->content, '', 'empty body' );
      }
      else {
            my $obj = eval { from_json( $res->content ) };
            fail("JSON $url => $@") if $@;
            return $obj;
      }
   }
   return undef;
}

sub add_value {
   my ( $variable_url, $date, $value ) = @_;

   $variable_url .= '/value';
   my $req = POST $variable_url,
      [
      'variable.value.put.value'         => $value,
      'variable.value.put.value_of_date' => $date,
      ];
   $req->method('PUT');
   my ( $res, $c ) = ctx_request($req);
   ok( $res->is_success, 'value ' . $value . ' on ' . $date . ' created!' );
   my $variable = eval { from_json( $res->content ) };
   return $variable;
}

# _populate($subvar[0]{id}, \@variacoes, '2010-01-01', qw/3 5 6 10/);
sub _populate {
   my ( $variavel, $arr_variacao, $data, @list ) = @_;

   my $i = 0;
   for my $var (@$arr_variacao) {
      my $val = $list[ $i++ ];
      next unless defined $val;
      my $res = &_post(
            201,
            '/api/indicator/' . $indicator->{id} . '/variables_variation/' . $variavel . '/values',
            [
               api_key                                                   => 'test',
               'indicator.variation_value.create.value'                  => $val,
               'indicator.variation_value.create.indicator_variation_id' => $var->{id},
               'indicator.variation_value.create.value_of_date'          => $data
            ]
      );
   }
}

