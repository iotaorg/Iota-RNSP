drop table _saida if exists ;
create temp table _saida as
select

    c.name as nome_cidade,
    c.uf as nome_uf,
    u.name as nome_usuario,
    a.name as nome_eixo,

    u.email as email,
    case when  (select count(1) from user_file x where u.id=x.user_id and x.class_name='programa_metas')>=1 then 'sim' else 'nao' end as programa_de_metas,

    func_status_indicadores_by_user(u.id, a.id, array(

        select distinct x.id
        from indicator x
        WHERE x.axis_id = a.id
        and (
            x.visibility_level='public'
            OR (
                x.visibility_level='private' AND x.visibility_user_id = u.id
            )
            OR (
                x.visibility_level='network' AND x.id IN (
                    select indicator_id from indicator_network_visibility
                    where network_id = 1
                )
            )
        )

    )) as qtde_indicadores_preenchido,
    func_status_indicadores_by_user_justificado(u.id, a.id,
        array(

            select distinct x.id
            from indicator x
            WHERE x.axis_id = a.id
            and (
                x.visibility_level='public'
                OR (
                    x.visibility_level='private' AND x.visibility_user_id = u.id
                )
                OR (
                    x.visibility_level='network' AND x.id IN (
                        select indicator_id from indicator_network_visibility
                        where network_id = 1
                    )
                )
            )

        )

    ) as qtde_indicadores_preenchido_ou_justificado,
    (
        select count(1)
        from indicator x
        WHERE x.axis_id = a.id
        and (
            x.visibility_level='public'
            OR (
                x.visibility_level='private' AND x.visibility_user_id = u.id
            )
            OR (
                x.visibility_level='network' AND x.id IN (
                    select indicator_id from indicator_network_visibility
                    where network_id = 1
                )
            )
        )
    ) as total_indicadores_eixo,
    c.id as city_id,
    a.id as axis_id,
    u.id as user_id

from "user" u
join city c on c.id=u.city_id
cross join axis a
where u.institute_id = 1
and u.city_id is not null;


copy _saida to '/tmp/status.indicadores.csv' CSV HEADER;