use strict;
use warnings;

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
        'num'  => '1.69',
        'name' => 'Pinheiros  ',
        'i'    => 0
    },
    {
        'num'  => '2.96',
        'name' => 'Vila Mariana   ',
        'i'    => 0
    },
    {
        'num'  => '5.95',
        'name' => 'Lapa   ',
        'i'    => 0
    },
    {
        'num'  => '6.42',
        'name' => 'Santo Amaro',
        'i'    => 0
    },
    {
        'num'  => '8.03',
        'name' => 'Sé ',
        'i'    => 0
    },
    {
        'num'  => '8.49',
        'name' => 'Santana/Tucuruvi   ',
        'i'    => 0
    },
    {
        'num'  => '8.66',
        'name' => 'Mooca  ',
        'i'    => 0
    },
    {
        'num'  => '10.07',
        'name' => 'Aricanduva ',
        'i'    => 0
    },
    {
        'num'  => '11.04',
        'name' => 'Ipiranga   ',
        'i'    => 1
    },
    {
        'num'  => '11.63',
        'name' => 'Penha  ',
        'i'    => 1
    },
    {
        'num'  => '11.83',
        'name' => 'Butantã',
        'i'    => 2
    },
    {
        'num'  => '12.97',
        'name' => 'Ermelino Matarazzo ',
        'i'    => 2
    },
    {
        'num'  => '13.03',
        'name' => 'Jabaquara  ',
        'i'    => 2
    },
    {
        'num'  => '13.07',
        'name' => 'Vila Prudente/Sapopemba',
        'i'    => 2
    },
    {
        'num'  => '13.15',
        'name' => 'Vila Maria/Vila Guilherme  ',
        'i'    => 2
    },
    {
        'num'  => '13.18',
        'name' => 'Itaquera   ',
        'i'    => 2
    },
    {
        'num'  => '13.34',
        'name' => 'Casa Verde/Cachoeirinha',
        'i'    => 3
    },
    {
        'num'  => '13.72',
        'name' => 'Pirituba   ',
        'i'    => 3
    },
    {
        'num'  => '14.91',
        'name' => 'Campo Limpo',
        'i'    => 4
    },
    {
        'num'  => '14.99',
        'name' => 'Jaçanã / Tremembé  ',
        'i'    => 4
    },
    {
        'num'  => '15.93',
        'name' => 'M´Boi Mirim',
        'i'    => 4
    },
    {
        'num'  => '15.93',
        'name' => 'Capela do Socorro  ',
        'i'    => 4
    },
    {
        'num'  => '16.01',
        'name' => 'Cidade Ademar  ',
        'i'    => 4
    },
    {
        'num'  => '16.38',
        'name' => 'São Miguel ',
        'i'    => 4
    },
    {
        'num'  => '16.47',
        'name' => 'Freguesia/Brasilândia  ',
        'i'    => 4
    },
    {
        'num'  => '17.29',
        'name' => 'Guaianases ',
        'i'    => 4
    },
    {
        'num'  => '17.42',
        'name' => 'Itaim Paulista ',
        'i'    => 4
    },
    {
        'num'  => '17.51',
        'name' => 'Perus  ',
        'i'    => 4
    },
    {
        'num'  => '17.65',
        'name' => 'São Mateus ',
        'i'    => 4
    },
    {
        'num'  => '19.08',
        'name' => 'Cidade Tiradentes  ',
        'i'    => 4
    },
    {
        'num'  => '19.12',
        'name' => 'Parelheiros',
        'i'    => 4
    }
];

is_deeply( $input, $var, 'math ok' );

done_testing;

