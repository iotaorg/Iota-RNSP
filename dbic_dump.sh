perl script/iota_create.pl model DB DBIC::Schema Iota::Schema create=static components=TimeStamp,PassphraseColumn 'dbi:Pg:dbname=iota_pcs;host=localhost' postgres system quote_names=1 overwrite_modifications=1

rm lib/Iota/Model/DB.pm.new;

