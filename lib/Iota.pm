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
    name     => 'Iota',
    encoding => 'UTF-8',

    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header                      => 1,    # Send X-Catalyst header

    private_path => 'root/static/user',
    public_url   => '/static/user',

    'Plugin::Assets' => {

        path        => '/static',
        output_path => 'built/',
        minify      => 1,
        stash_var   => 'assets'
    },

    'View::HTML' => { expose_methods => [ 'date4period', 'value4human', 'l' ] },

    'I18N::DBI' => {
        languages    => [qw(pt-br es)],
        lexicons     => [qw(*)],
        lex_class    => 'DB::Lexicon',
        default_lang => 'pt-br',
    },
);

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
