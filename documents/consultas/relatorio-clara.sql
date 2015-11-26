drop table _saida;
create temp table _saida as
select

    c.name as nome_cidade,
    c.uf as nome_uf,
    u.name as nome_usuario,
    a.name as nome_eixo,

    u.email as email,

    (select count(distinct x.id)
        from indicator x
        WHERE x.axis_id = a.id
        and (

                 x.visibility_level='private' AND x.visibility_user_id IN (
                    u.id
                )
        )) as qtde_indicadores_privados,

    func_status_indicadores_by_user(u.id, a.id, array(

        select distinct x.id
        from indicator x
        WHERE x.axis_id = a.id
        and (

                 x.visibility_level='private' AND x.visibility_user_id IN (
                    u.id
                )
        )

    )) as qtde_indicadores_preenchido,
    func_status_indicadores_by_user_justificado(u.id, a.id,
        array(

            select distinct x.id
            from indicator x
            WHERE x.axis_id = a.id
            and (
                x.visibility_level='private' AND x.visibility_user_id IN (
                    u.id
                )
            )

        )

    ) as qtde_indicadores_preenchido_ou_justificado,

    c.id as city_id,
    a.id as axis_id,
    u.id as user_id

from "user" u
join city c on c.id=u.city_id
cross join axis a
where u.institute_id = 1
and u.city_id is not null
order by qtde_indicadores_privados desc;

select * from _saida;

copy _saida to '/tmp/indicadores.privados.csv' CSV HEADER;

