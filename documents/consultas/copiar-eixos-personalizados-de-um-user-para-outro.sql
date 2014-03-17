-- 764 = origem
-- 797 = destino

create table _tmp_copia_axis as  select a.id, b.user_indicator_axis_id,  a.name, a.position, b.indicator_id, b.position as item_position
  from user_indicator_axis a  join   user_indicator_axis_item b on b.user_indicator_axis_id = a.id where user_id =  764 ;

insert into user_indicator_axis (name, position, user_id) select name, position, 797 from _tmp_copia_axis
 where (name, position) not in (select name, position from user_indicator_axis where user_id= 797) group by 1,2;

insert into user_indicator_axis_item (user_indicator_axis_id, indicator_id, "position")
select a.id, b.indicator_id, b.position from user_indicator_axis a join _tmp_copia_axis b on a.name = b.name where user_id= 797;

-- drop table _tmp_copia_axis;
