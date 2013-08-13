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

my $cache_lang_file = "/tmp/cache.lang.$$";


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

    $c->lexicon_reload;
}

sub lexicon_reload {

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

    unless (-e $cache_lang_file){
        &lexicon_reload;
    }

    if (exists $cache->{$current_lang}{$text}){
        return $cache->{$current_lang}{$text};
    }else {
        my $str = $current_lang eq 'pt-br' ? $text : "? $text";
        $cache->{$current_lang}{$text} = $str;

        $resultset->find_or_create({
            lang     => $current_lang,
            lex      => '*',
            lex_key  => $text,
            lex_value => $str
        });

        return $str;
    }

}

sub set_lang {
    my (  $c, $lang) = @_;
    $current_lang = $lang;
}

__PACKAGE__;

__END__

# use $c->logx('your message', ? {indicator_id => 123}) anywhere you want.

