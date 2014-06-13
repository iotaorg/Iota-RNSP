package CatalystX::Plugin::Lexicon;

use Moose;
with 'MooseX::Emulate::Class::Accessor::Fast';
use MRO::Compat;
use Catalyst::Exception ();
use Data::Dumper;

use overload ();
use Carp;

use namespace::clean -except => 'meta';

our $VERSION = '0.35';
$VERSION = eval $VERSION;

my $resultset;
my $cache;
my $current_lang;

my $cache_lang_prefix = '/tmp/cache.lang.';

sub setup {
    my $c = shift;

    $c->maybe::next::method(@_);

    return $c;
}

sub initialize_after_setup {
    my ( $self, $c ) = @_;

    $c->setup_lexicon_plugin($c);
}

sub setup_lexicon_plugin {
    my ( $self, $c ) = @_;

    my $db = $c->model('DB');
    $resultset = $db->resultset('Lexicon');

    $c->config->{default_lang}   ||= 'pt-br';
    $c->config->{forced_langs}   ||= 'pt-br';
    $c->config->{admin_langs_id} ||= 1;

    $current_lang = $c->config->{default_lang};

    $c->lexicon_reload_self;
}

sub lexicon_reload_all {
    my @files = glob("$cache_lang_prefix*");
    unlink $_ for @files;
}

sub lexicon_reload_self {

    my @load = $resultset->search( undef, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' } )->all;

    $cache = {};
    foreach my $r (@load) {
        $cache->{ $r->{lang} }{ $r->{lex_key} } = $r->{lex_value};
    }

    my $cache_lang_file = "$cache_lang_prefix$$";
    open my $FG, '>', $cache_lang_file;
    print $FG '1';
    close $FG;
}

sub loc {
    my ( $c, $text, $origin_lang, @conf ) = @_;

    return $text if ( !defined $text || $text eq '' );

    my $default = $c->config->{default_lang};

    $origin_lang =
        $origin_lang ? $origin_lang
      : $c->user && $c->user_in_realm('default')    ? $c->user->cur_lang
      :                $default;

    my $cache_lang_file = "$cache_lang_prefix$$";
    unless ( -e $cache_lang_file ) {
        &lexicon_reload_self;
    }

    if ( exists $cache->{$current_lang}{$text} ) {
        return $cache->{$current_lang}{$text};
    }
    else {

        my $user_id = $c->user && $c->user_in_realm('default') ? $c->user->id : $c->config->{admin_langs_id};
        my @add_langs = split /,/, $c->config->{forced_langs};

        foreach my $lang (@add_langs) {
            my $str = $lang eq $origin_lang ? $text : "? $text";
            $cache->{$lang}{$text} = $str;

            my $exists = $resultset->search(
                {
                    lex     => '*',
                    lang    => $lang,
                    lex_key => $text,
                }
            )->count;

            if ( $exists == 0 ) {
                $resultset->create(
                    {
                        lex         => '*',
                        lang        => $lang,
                        lex_key     => $text,
                        lex_value   => $str,
                        user_id     => $user_id,
                        origin_lang => $origin_lang
                    }
                );
            }
        }
        return $current_lang eq $origin_lang ? $text : "? $text";
    }

}

sub set_lang {
    my ( $c, $lang ) = @_;
    $current_lang = $lang;
}

sub get_lang {
    my ($c) = @_;
    return $current_lang;
}

__PACKAGE__;

__END__

# use $c->logx('your message', ? {indicator_id => 123}) anywhere you want.

