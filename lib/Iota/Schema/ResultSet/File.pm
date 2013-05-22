
package Iota::Schema::ResultSet::File;

use namespace::autoclean;

use Moose;

extends 'DBIx::Class::ResultSet';

with 'Iota::Schema::Role::InflateAsHashRef';

1;

