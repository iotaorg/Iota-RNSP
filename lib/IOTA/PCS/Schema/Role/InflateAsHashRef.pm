package IOTA::PCS::Schema::Role::InflateAsHashRef;

use Moose::Role;

sub as_hashref {
    shift->search_rs( undef, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' } );
}
1;

