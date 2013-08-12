alter table institute add column bypass_indicator_axis_if_custom boolean not null default true;
alter table institute add column hide_empty_indicators boolean not null default false;


alter table institute add column license varchar;
alter table institute add column license_url varchar;

alter table institute add column image_url varchar;


alter table institute add column datapackage_autor       varchar;
alter table institute add column datapackage_autor_email varchar;