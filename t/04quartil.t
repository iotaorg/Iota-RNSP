use strict;
use warnings;

use Test::More;
use Test::Deep;


use Data::Printer;
BEGIN { use_ok 'Iota::Statistics::Quartile' }

my $test  = new_ok 'Iota::Statistics::Quartile';
my $input = [
    { name => 'Pinheiros  ', num => 1.69 },
    { name => 'Vila Mariana   ', num => 2.96 },
    { name => 'Lapa   ', num => 5.95 },
    { name => 'Santo Amaro', num => 6.42 },
    { name => 'Sé ', num => 8.03 },
    { name => 'Santana/Tucuruvi   ', num => 8.49 },
    { name => 'Mooca  ', num => 8.66 },
    { name => 'Aricanduva ', num => 10.07 },
    { name => 'Ipiranga   ', num => 11.04 },
    { name => 'Penha  ', num => 11.63 },
    { name => 'Butantã', num => 11.83 },
    { name => 'Ermelino Matarazzo ', num => 12.97 },
    { name => 'Jabaquara  ', num => 13.03 },
    { name => 'Vila Prudente/Sapopemba', num => 13.07 },
    { name => 'Vila Maria/Vila Guilherme  ', num => 13.15 },
    { name => 'Itaquera   ', num => 13.18 }   ,
    { name => 'Casa Verde/Cachoeirinha', num => 13.34 },
    { name => 'Pirituba   ', num => 13.72 },
    { name => 'Campo Limpo', num => 14.91 },
    { name => 'Jaçanã / Tremembé  ', num => 14.99 },
    { name => 'M´Boi Mirim', num => 15.93 },
    { name => 'Capela do Socorro  ', num => 15.93 },
    { name => 'Cidade Ademar  ', num => 16.01 },
    { name => 'São Miguel ', num => 16.38 },
    { name => 'Freguesia/Brasilândia  ', num => 16.47 },
    { name => 'Guaianases ', num => 17.29 },
    { name => 'Itaim Paulista ', num => 17.42 },
    { name => 'Perus  ', num => 17.51 },
    { name => 'São Mateus ', num => 17.65 } ,
    { name => 'Cidade Tiradentes  ', num => 19.08 },
    { name => 'Parelheiros', num => 19.12 },
];

$test->iterate($input);
map { print STDERR $_->{name}. " => " . $_->{num} . ' : ' . $_->{qt} ."\n" } @{$input};


done_testing;

