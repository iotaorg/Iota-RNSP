perl script/rnsp_pcs_create.pl model RNSP::PCS DBIC::Schema RNSP::PCS::Schema create=static components=TimeStamp,PassphraseColumn 'dbi:Pg:dbname=rnsp_pcs;host=localhost' postgres system quote_names=1 overwrite_modifications=1
rm lib/RNSP/PCS/Model/RNSP/PCS.pm
rmdir lib/RNSP/PCS/Model/RNSP
rm t/model_RNSP-PCS.t