-- campos para marcar que os registros devem ser calculados a partir dos filhos
-- criados sozinho pelo sistema
alter table region add column automatic_fill boolean not null default false;
alter table city add column automatic_fill boolean not null default false;

