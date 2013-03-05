perl script/iota_pcs_create.pl model DB DBIC::Schema Iota::PCS::Schema create=static components=TimeStamp,PassphraseColumn 'dbi:Pg:dbname=iota_pcs;host=localhost' postgres system quote_names=1 overwrite_modifications=1

rm lib/Iota/PCS/Model/DB.pm.new;

