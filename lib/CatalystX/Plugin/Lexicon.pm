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
my $cache_lang_file = "$cache_lang_prefix$$";


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

    $c->config->{default_lang} ||= 'pt-br';
    $c->config->{forced_langs} ||= 'pt-br';
    $c->config->{admin_langs_id} ||= 1;

    $current_lang = $c->config->{default_lang};

    $c->lexicon_reload_self;
}


sub lexicon_reload_all {
    my @files = glob("$cache_lang_prefix*");
    unlink $_ for @files;
}

sub lexicon_reload_self {

    my @load = $resultset->search(
        undef,
        { result_class => 'DBIx::Class::ResultClass::HashRefInflator' }
    )->all;

    $cache = {};
    foreach my $r(@load){
        $cache->{$r->{lang}}{$r->{lex_key}} = $r->{lex_value};
    }

    open my $FG, '>', $cache_lang_file;
    print $FG Dumper $cache;
    close $FG;
}

sub loc {
    my ( $c, $text, @conf ) = @_;
    my $default = $c->config->{default_lang};


    unless (-e $cache_lang_file){
        &lexicon_reload_self;
    }

    if (exists $cache->{$current_lang}{$text}){
        return $cache->{$current_lang}{$text};
    }else {

        my $user_id = $c->user ? $c->user->id : $c->config->{admin_langs_id};
        my @add_langs = split /,/, $c->config->{forced_langs};

        foreach my $lang (@add_langs){

            my $str = $lang eq $default ? $text : "? $text";
            $cache->{$lang}{$text} = $str;

            $resultset->find_or_create({
                lang      => $lang,
                lex       => '*',
                lex_key   => $text,
                lex_value => $str,
                user_id   => $user_id
            });

        }

        return $current_lang eq $default ? $text : "! $text";
    }

}

sub set_lang {
    my (  $c, $lang) = @_;
    $current_lang = $lang;
}

__PACKAGE__;

__END__

# use $c->logx('your message', ? {indicator_id => 123}) anywhere you want.

