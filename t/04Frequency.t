use strict;
use warnings;
use utf8;

use Test::More;
use Test::Deep;

use Data::Printer;
BEGIN { use_ok 'Iota::Statistics::Frequency' }

my $test  = new_ok 'Iota::Statistics::Frequency';
my $input = [
    { name => 'Pinheiros  ',                 num => 1.69 },
    { name => 'Vila Mariana   ',             num => 2.96 },
    { name => 'Lapa   ',                     num => 5.95 },
    { name => 'Santo Amaro',                 num => 6.42 },
    { name => 'Sé ',                        num => 8.03 },
    { name => 'Santana/Tucuruvi   ',         num => 8.49 },
    { name => 'Mooca  ',                     num => 8.66 },
    { name => 'Aricanduva ',                 num => 10.07 },
    { name => 'Ipiranga   ',                 num => 11.04 },
    { name => 'Penha  ',                     num => 11.63 },
    { name => 'Butantã',                    num => 11.83 },
    { name => 'Ermelino Matarazzo ',         num => 12.97 },
    { name => 'Jabaquara  ',                 num => 13.03 },
    { name => 'Vila Prudente/Sapopemba',     num => 13.07 },
    { name => 'Vila Maria/Vila Guilherme  ', num => 13.15 },
    { name => 'Itaquera   ',                 num => 13.18 },
    { name => 'Casa Verde/Cachoeirinha',     num => 13.34 },
    { name => 'Pirituba   ',                 num => 13.72 },
    { name => 'Campo Limpo',                 num => 14.91 },
    { name => 'Jaçanã / Tremembé  ',      num => 14.99 },
    { name => 'M´Boi Mirim',                num => 15.93 },
    { name => 'Capela do Socorro  ',         num => 15.93 },
    { name => 'Cidade Ademar  ',             num => 16.01 },
    { name => 'São Miguel ',                num => 16.38 },
    { name => 'Freguesia/Brasilândia  ',    num => 16.47 },
    { name => 'Guaianases ',                 num => 17.29 },
    { name => 'Itaim Paulista ',             num => 17.42 },
    { name => 'Perus  ',                     num => 17.51 },
    { name => 'São Mateus ',                num => 17.65 },
    { name => 'Cidade Tiradentes  ',         num => 19.08 },
    { name => 'Parelheiros',                 num => 19.12 },
];

$test->iterate($input);
my $var = [
    {
        'name' => 'Pinheiros  ',
        'num'  => '1.69',
        'i'    => 0
    },
    {
        'num'  => '2.96',
        'i'    => 0,
        'name' => 'Vila Mariana   '
    },
    {
        'num'  => '5.95',
        'i'    => 1,
        'name' => 'Lapa   '
    },
    {
        'name' => 'Santo Amaro',
        'num'  => '6.42',
        'i'    => 1
    },
    {
        'name' => "S\x{e9} ",
        'num'  => '8.03',
        'i'    => 1
    },
    {
        'num'  => '8.49',
        'i'    => 1,
        'name' => 'Santana/Tucuruvi   '
    },
    {
        'num'  => '8.66',
        'i'    => 1,
        'name' => 'Mooca  '
    },
    {
        'name' => 'Aricanduva ',
        'num'  => '10.07',
        'i'    => 2
    },
    {
        'name' => 'Ipiranga   ',
        'i'    => 2,
        'num'  => '11.04'
    },
    {
        'num'  => '11.63',
        'i'    => 2,
        'name' => 'Penha  '
    },
    {
        'i'    => 2,
        'num'  => '11.83',
        'name' => "Butant\x{e3}"
    },
    {
        'i'    => 3,
        'num'  => '12.97',
        'name' => 'Ermelino Matarazzo '
    },
    {
        'i'    => 3,
        'num'  => '13.03',
        'name' => 'Jabaquara  '
    },
    {
        'name' => 'Vila Prudente/Sapopemba',
        'i'    => 3,
        'num'  => '13.07'
    },
    {
        'name' => 'Vila Maria/Vila Guilherme  ',
        'i'    => 3,
        'num'  => '13.15'
    },
    {
        'num'  => '13.18',
        'i'    => 3,
        'name' => 'Itaquera   '
    },
    {
        'num'  => '13.34',
        'i'    => 3,
        'name' => 'Casa Verde/Cachoeirinha'
    },
    {
        'num'  => '13.72',
        'i'    => 3,
        'name' => 'Pirituba   '
    },
    {
        'name' => 'Campo Limpo',
        'i'    => 3,
        'num'  => '14.91'
    },
    {
        'name' => "Ja\x{e7}an\x{e3} / Trememb\x{e9}  ",
        'num'  => '14.99',
        'i'    => 3
    },
    {
        'name' => "M\x{b4}Boi Mirim",
        'num'  => '15.93',
        'i'    => 4
    },
    {
        'name' => 'Capela do Socorro  ',
        'num'  => '15.93',
        'i'    => 4
    },
    {
        'i'    => 4,
        'num'  => '16.01',
        'name' => 'Cidade Ademar  '
    },
    {
        'i'    => 4,
        'num'  => '16.38',
        'name' => "S\x{e3}o Miguel "
    },
    {
        'num'  => '16.47',
        'i'    => 4,
        'name' => "Freguesia/Brasil\x{e2}ndia  "
    },
    {
        'name' => 'Guaianases ',
        'num'  => '17.29',
        'i'    => 4
    },
    {
        'name' => 'Itaim Paulista ',
        'num'  => '17.42',
        'i'    => 4
    },
    {
        'i'    => 4,
        'num'  => '17.51',
        'name' => 'Perus  '
    },
    {
        'name' => "S\x{e3}o Mateus ",
        'num'  => '17.65',
        'i'    => 4
    },
    {
        'name' => 'Cidade Tiradentes  ',
        'i'    => 4,
        'num'  => '19.08'
    },
    {
        'name' => 'Parelheiros',
        'i'    => 4,
        'num'  => '19.12'
    }
];

is_deeply( $input, $var, 'math ok' );

done_testing;

