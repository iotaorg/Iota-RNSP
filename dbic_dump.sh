perl script/iota_pcs_create.pl model DB DBIC::Schema IOTA::PCS::Schema create=static components=TimeStamp,PassphraseColumn 'dbi:Pg:dbname=rnsp_pcs;host=localhost' postgres system quote_names=1 overwrite_modifications=1

rm lib/IOTA/PCS/Model/DB.pm.new;

