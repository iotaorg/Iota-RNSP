
package RNSP::PCS::Model::DB;
use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'RNSP::PCS::Schema',
);

