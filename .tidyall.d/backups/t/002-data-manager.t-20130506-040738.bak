use strict;
use warnings;

use Test::More;
use Data::Verifier;

BEGIN { use_ok 'Iota::Data::Manager' }

my $verifier_default_args = [
  filters => [qw(trim)],
  profile => {
    name => {
      required => 1,
      type     => 'Str',
      filters  => [qw(collapse)]
    },
    age  => { type => 'Int' },
    sign => {
      required => 1,
      type     => 'Str'
    }
  }
];
my $verifiers = {
  'foo'          => $verifier_default_args,
  'foo.bar'      => $verifier_default_args,
  'foo.bar.quux' => $verifier_default_args
};

my $isa_result_ok = sub {
  my $r = shift;
  isa_ok( $r, 'Data::Verifier::Results' );
  ok( $r->success, 'success' );
};

my $never_called = 1;
my $isa_result_err = sub {
  my $never_called = 0;
  # my $r = shift;
  # isa_ok( $r, 'Data::Verifier::Results' );
  # ok( !$r->success, 'error expected' );
};


my $actions = {
  'foo'          => $isa_result_ok,
  'foo.bar'      => $isa_result_err,
  'foo.bar.quux' => $isa_result_ok,
};

my $args = { name => 'bar', age => 100, sign => 'plus' };
my $args_err = { name => 'bar', age => 'hundred', sign => 'plus' };

my $dm = new_ok 'Iota::Data::Manager' => [
  input     => { foo => $args, 'foo.bar' => $args_err, 'foo.bar.quux' => $args },
  verifiers => {
    map { $_ => Data::Verifier->new( @{ $verifiers->{$_} } ) } keys %$verifiers
  },
  actions => $actions
];

ok( $dm->apply, 'apply ok' );
ok($never_called, 'didnt call the action with result error');

ok($dm->get_results('foo')->success, 'foo success');
ok(!$dm->get_results('foo.bar')->success, 'foo.bar has an error');
ok($dm->get_results('foo.bar.quux')->success, 'foo.bar.quux success');

done_testing;

