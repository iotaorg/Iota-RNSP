package Iota;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;
use open qw(:std :utf8);

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
  ConfigLoader
  Static::Simple
  Params::Nested

  Authentication
  Authorization::Roles

  +CatalystX::Plugin::Logx
  +CatalystX::Plugin::Lexicon

  Assets

  StatusMessage

  Session::DynamicExpiry
  Session

  Session::Store::File
  Session::State::Cookie
  Session::PerUser

  /;

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in iota_pcs.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name                 => 'Iota',
    encoding             => 'UTF-8',
    using_frontend_proxy => 1,

    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header                      => 1,    # Send X-Catalyst header

    private_path => 'root/static/user',
    public_url   => '/static/user',

    'Plugin::Assets' => {

        path        => '/static',
        output_path => 'built/',
        minify      => 0,
        stash_var   => 'assets'
    },

    'View::HTML' => { expose_methods => [ 'date4period', 'value4human', 'l', 'to_json_tpl' ] },

    # cache geral, carregado do banco quando recebe o valor de dynamic
    rdf_domain => 'dynamic'

);

before 'setup_components' => sub {
    my $app = shift;

    if ( !$ENV{TOGEOJSON_BIN} ) {

        my ( undef, $bin ) = split / /, `whereis togeojson`;
        chomp($bin);

        if ( -x $bin ) {
            $ENV{TOGEOJSON_BIN} = $bin;
        }

    }

    if ( $ENV{HARNESS_ACTIVE} || $0 =~ /forkprove/ ) {
        $app->config->{'Model::DB'}{connect_info} = $app->config->{'Model::DB'}{testing_connect_info};
    }

    if ( $ENV{CATALYST_ENV} && $ENV{CATALYST_ENV} eq 'development' ) {
        $app->config->{'Model::DB'}{connect_info} = $app->config->{'Model::DB'}{development_connect_info};
    }

};

after 'setup_components' => sub {
    my $app = shift;
    for ( keys %{ $app->components } ) {
        if ( $app->components->{$_}->can('initialize_after_setup') ) {
            $app->components->{$_}->initialize_after_setup($app);
        }
    }

};

after setup_finalize => sub {
    my $app = shift;

    for ( $app->registered_plugins ) {
        if ( $_->can('initialize_after_setup') ) {
            $_->initialize_after_setup($app);
        }
    }
};

around 'apply_default_middlewares' => sub {
    my $orig = shift;
    my $app  = shift->$orig(@_);

    sub {
        my $env = shift;
        if ( $env->{PATH_INFO} =~ m/^\/?(prefeitura|movimento)(.*)/i ) {

            my $sites = {
                prefeitura => 'indicadores.cidadessustentaveis.org.br',
                movimento  => 'www.redesocialdecidades.org.br'
            };

            my $redir_url = 'http://' . $sites->{ lc $1 } . ( $2 || '' );
            return [ 301, [ "Location" => $redir_url ], ["Moved"] ];
        }

        $app->($env);
    };
};

sub resize_image {
    my ( $c, $self, $private_path, $scale, $output_path ) = @_;

    $scale       = $scale       ? $scale       : 1;
    $output_path = $output_path ? $output_path : $private_path;

    eval('require Imager');
    return if $@;

    my $img = Imager->new( file => $private_path )
      or $self->status_bad_request( $c, message => Imager->errstr() ), $c->detach;

    my $ratio = $img->getwidth() / $img->getheight();

    if ( $ratio > 1 ) {
        if ( $img->getwidth() > 1280 * $scale ) {
            $img = $img->scale( xpixels => 1280 * $scale );
        }
        if ( $img->getheight() > 720 * $scale ) {
            $img = $img->scale( ypixels => 720 * $scale );
        }
    }
    else {
        if ( $img->getwidth() > 720 * $scale ) {
            $img = $img->scale( xpixels => 720 * $scale );
        }

        if ( $img->getheight() > 1280 * $scale ) {
            $img = $img->scale( ypixels => 1280 * $scale );
        }
    }

    $img->write( file => $output_path, type => $private_path =~ /.png$/ ? 'png' : 'jpeg' )
      or $self->status_bad_request( $c, message => Imager->errstr() ), $c->detach;
}

# Start the application
__PACKAGE__->setup();

=head1 NAME

Iota - Catalyst based application

=head1 SYNOPSIS

    script/iota_pcs_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<Iota::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Thiago Rondon

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
