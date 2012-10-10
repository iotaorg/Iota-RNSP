use utf8;
package RNSP::PCS::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07028 @ 2012-09-03 13:32:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AE4hVT0kix+JcrTd5vAhhA


sub AUTOLOAD {
    ( my $name = our $AUTOLOAD ) =~ s/.*:://;
    no strict 'refs';

    # isso cria na hora a sub e não é recompilada \m/ perl nao é lindo?!
    *$AUTOLOAD = sub {
        my ( $self, @args ) = @_;
        my $res = eval {
            $self->storage->dbh->selectrow_hashref( "select * from $name ( " . substr( '?,' x @args, 0, -1 ) . ')',
                undef, @args );
        };
        do { print $@; return undef } if $@;
        return $res;
    };
    goto &$AUTOLOAD;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
