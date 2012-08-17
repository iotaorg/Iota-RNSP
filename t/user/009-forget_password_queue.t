use strict;
use warnings;

use Test::More;

use Catalyst::Test q(RNSP::PCS);

use HTTP::Request::Common;

use JSON qw(decode_json);

my $schema = RNSP::PCS->model('DB');
eval {
  $schema->txn_do(
    sub {
      my ( $res, $c );
        my $city = $schema->resultset('City')->create(
            {   type => 'prefeitura',
                uf   => 'SP',
                name => 'Pederneiras'
            },
        );
        $schema->resultset('User')->create(
        {
          name         => 'Foo Bar Quux',
          email        => 'foo@email.com',
          password     => '1234',
          city         => $city
        },
      );

      ( $res, $c ) = ctx_request(
        POST '/api/user/forgot_password/email',
        [
          'user.forgot_password.email' => 'foo@email.com',
        ]
      );

      like( $res->content, qr/\bok\b/i, 'email ok' );
      ok( $res->is_success, 'resposta ok' );

		  ok(
        my $lostkey =
          $schema->resultset('User')->find( { email => 'foo@email.com' } )->user_forgotten_passwords->first,
          'user have a lost key'
      );


			is(
          $schema->resultset('EmailsQueue')->search( { to => 'foo@email.com' } )->count,
				1,
        'a tabela de queue tem um registro'
      );



      die 'rollback';
    }
  );

};

die $@ unless $@ =~ /rollback/;

done_testing;
