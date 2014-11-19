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

}
use Digest::MD5 qw(md5_hex);

sub lexicon_reload_all {
    my @files = glob("$cache_lang_prefix*");
    unlink $_ for @files;
}

sub lexicon_reload_self {

    my $rs = $resultset->search( undef, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' } );

    $cache = {};
    while ( my $r = $rs->next ) {
        $cache->{ $r->{lang} }{ $r->{lex_key} } = $r->{lex_value};
    }

    my $cache_lang_file = "$cache_lang_prefix$$";
    open my $FG, '>', $cache_lang_file;
    print $FG '1';
    close $FG;
}

sub valid_values_for_lex_key {
    my ( $self, $lex ) = @_;
    return wantarray ? () : {} unless $lex;

    my $cache_lang_file = "$cache_lang_prefix$$";
    unless ( -e $cache_lang_file ) {
        &lexicon_reload_self;
    }
    my $out = {};
    foreach my $lang ( keys %$cache ) {
        if ( exists $cache->{$lang}{$lex} && $cache->{$lang}{$lex} !~ /^\?\s/ && $cache->{$lang}{$lex} ) {
            $out->{$lang} = $cache->{$lang}{$lex};
        }
    }
    wantarray ? %$out : $out;
}

=pod

update lexicon m set translated_from_lexicon = true,
lex_value = (select x.lex_key from lexicon x where x.lang = 'es' and x.origin_lang='pt-br' and x.lex_value=m.lex_key order by length(lex_key) limit 1)
where origin_lang='es' and lang='pt-br' and lex_key in (select lex_value from lexicon where lang = 'es' and origin_lang='pt-br');


update lexicon m set translated_from_lexicon = true,
lex_value = (select x.lex_key from lexicon x where x.lang = 'pt-br' and x.origin_lang='es' and x.lex_value=m.lex_key order by length(lex_key) limit 1)
where origin_lang='pt-br' and lang='es' and lex_key in (select lex_value from lexicon where lang = 'pt-br' and origin_lang='es') and lex_value like '? %';




=cut

sub loc {
    my ( $c, $text, $origin_lang, @conf ) = @_;

    return $text if exists $ENV{HARNESS_ACTIVE} && $ENV{HARNESS_ACTIVE};
    return $text if ( !defined $text || $text =~ /^\s+$/ );

    $text =~ s/^\s+//;
    $text =~ s/\s+$//;

    my $default = $c->config->{default_lang};

    # o HARNESS_ACTIVE eh desabilitado no teste que usamos.
    my $is_user = $c->user && ( $ENV{HARNESS_ACTIVE_REMOVED} || $c->user_in_realm('default') );

    $origin_lang =
        $origin_lang ? $origin_lang
      : $is_user     ? $c->user->cur_lang
      :                $default;

    my $cache_lang_file = "$cache_lang_prefix$$";
    unless ( -e $cache_lang_file ) {
        &lexicon_reload_self;
    }

    if ( exists $cache->{$current_lang}{$text} ) {
        return $cache->{$current_lang}{$text};
    }
    else {

        my $user_id = $is_user ? $c->user->id : $c->config->{admin_langs_id};
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
                eval {
                    $resultset->create(
                        {
                            lex       => '*',
                            lang      => $lang,
                            lex_key   => $text,
                            lex_value => \[
                                "coalesce(
                                            (select x.lex_key from lexicon x where x.lang = ?
                                                and x.origin_lang = ?
                                                and x.lex_value   = ?
                                                order by length(lex_key) limit 1), ?)", $origin_lang, $lang, $text, $str
                            ],

                            translated_from_lexicon => \[
                                "coalesce(
                                            (select true from lexicon x where x.lang = ?
                                                and x.origin_lang = ?
                                                and x.lex_value   = ?
                                                order by length(lex_key) limit 1), NULL)", $origin_lang, $lang, $text
                            ],

                            user_id     => $user_id,
                            origin_lang => $origin_lang
                        }
                    );
                };
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

