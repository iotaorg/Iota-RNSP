use strict;
use warnings;

use Test::More;
use Test::Deep;

use Data::Printer;
BEGIN { use_ok 'Iota::PCS::Data::Visitor' }

my $v = new_ok 'Iota::PCS::Data::Visitor';
my $action= sub {1};
my $d = {
  x => 0,
  foo => {
    z => 0,
    bar  => { a => $action, b => 33 },
    quux => { c => 44, d => 55, baz => { e => 66, f => 77 } }
  }
};

ok( !$v->visit($d), 'visit ok' );
cmp_deeply(
  $v->final_value,
  {
    'x' => 0,
    'foo' => {z => 0},
    'foo.bar' => { a => $action, b => 33 },
    'foo.quux'     => { c => 44, d => 55 },
    'foo.quux.baz' => { e => 66, f => 77 }
  }
);
done_testing;

