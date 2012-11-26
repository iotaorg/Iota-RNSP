package CatalystX::Plugin::Logx;

use Moose;
with 'MooseX::Emulate::Class::Accessor::Fast';
use MRO::Compat;
use Catalyst::Exception ();

use overload ();
use MongoDB;
use Carp;
use Cwd 'abs_path';

use namespace::clean -except => 'meta';

our $VERSION = '0.35';
$VERSION = eval $VERSION;

my $resultset;

sub setup {
  my $c = shift;

  $c->maybe::next::method(@_);

  return $c;
}

sub initialize_after_setup {
    my ($self, $c) = @_;
    $c->setup_logx_plugin($c);
}

sub setup_logx_plugin {
  my ($self, $c) = @_;

  my $db = $c->model('DB');
  $resultset = $db->resultset('ActionLog');

}


sub logx {
    my ( $c, $msg, %conf ) = @_;

    my $create = {message => $msg};

    eval {
        if ( eval { $c->req } )
        {
            $create->{ip}  = $c->req->address;
            $create->{url} = $c->req->method . ' /' . $c->req->path;
        }

        if ( eval { $c->user } ) {
            my $u = $c->user;
            $create->{user_id} = $u->id;
        }

        $create->{indicator_id} = $conf{indicator_id} if exists $conf{indicator_id};

        $resultset->create($create)
    };
    print $@ if $@;

}

__PACKAGE__;

__END__

# use $c->logx('your message', ? {indicator_id => 123}) anywhere you want.

