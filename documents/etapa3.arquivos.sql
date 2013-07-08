alter table user_file add column hide_listing boolean not null default false;
alter table user_file add column description varchar;
alter table user_file add column public_name varchar;