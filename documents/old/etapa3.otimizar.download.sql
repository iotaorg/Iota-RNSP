
create index ix_indicator_value__valid_from_user_id_indicator_id on indicator_value(valid_from, user_id, indicator_id);
create index ix_user_indicator__valid_from_user_id_indicator_id on user_indicator(valid_from, user_id, indicator_id);
create index ix_user_indicator_config__valid_from_user_id_indicator_id on user_indicator_config( user_id, indicator_id);

vacuum analyse indicator_value;
vacuum analyse user_indicator;
vacuum analyse  user_indicator_config;
