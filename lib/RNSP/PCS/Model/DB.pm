

package RNSP::PCS::Model::DB;
use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'RNSP::PCS::Schema',

    connect_info => {
        dsn        => 'dbi:Pg:dbname=rnsp_pcs',
        AutoCommit => q{1},
        quote_char => q{"},
        name_sep   => q{.}
    }
);

