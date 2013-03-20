Administração do SuperAdmin
==================

Visão geral
----------

* Preferencias
* Países
* Estados
* Cidades
* Redes
* Administradores
* Indicadores



Detalhes
-------


*   Preferencias [instituição]

    Um pedaço das preferencias do superadmin é para controlar as permissões de cada instituição.

    -------

    **Institutos**

    Para listar os institutos:

        GET /api/institute

    Retorna a lista, são apenas duas, movimento e prefeitura.

        GET /api/institute/$id

    Retorna os dados da instituição em sí. porem todos os dados já estão na lista.

        PUT /api/institute/$id

    Atualiza os dados de uma instituição. Campos:

        institute.update.users_can_edit_value       = boolean
        institute.update.users_can_edit_groups      = boolean
        institute.update.can_use_custom_css         = boolean
        institute.update.can_use_custom_pages       = boolean

        institute.update.name          = string
        institute.update.short_name    = string
        institute.update.description   = string

    O cadastro tem os mesmos campos (no namespace create) e fica em

        POST /api/institute

    Porém, no momento, não precisa fazer esse cadastro no frontend,
    pois as duas utilizadas já estão cadastradas.

    **Demais items**

    Ainda não tem. Provavelmente vai aparecer algum.

*   Países

    Cadastro de países do sistema, que são utilizados para criar os estados.

    -------

    Para listar eles:

        GET /api/country

    Para pegar detalhes de um mesmo:

        GET /api/country/$id

    Para remover

        DELETE /api/country/$id

    note que para remoção, não pode existir mais nenhum estado, nem cidade utilizando ele.

    Para cadastrar um novo:

        POST /api/country

        namespace = country.create

    Para atualizar um existente:

        PUT /api/country/$id

        namespace = country.update


    Campos:


        $namespace.name          = string
        $namespace.name_url      = string, opcional


*   Estados

    Cadastro de estados do sistema, que são utilizados para criar as cidades.

    -------

    Para listar eles:

        GET /api/state

    Para pegar detalhes de um mesmo:

        GET /api/state/$id

    Para remover

        DELETE /api/state/$id

    note que para remoção, não pode existir mais nenhuma cidade utilizando o item.

    Para cadastrar um novo:

        POST /api/state

        namespace = state.create

    Para atualizar um existente:

        PUT /api/state/$id

        namespace = state.update


    Campos:


        $namespace.country_id    = int
        $namespace.name          = string
        $namespace.uf            = string
        $namespace.name_url      = string, opcional, vem com base no campo uf

*   Cidades

    Cadastro de cudades do sistema, que são utilizados para ligar aos usuarios.

    -------

    Para listar elas:

        GET /api/city

    Para pegar detalhes da mesma:

        GET /api/city/$id

    Para remover

        DELETE /api/city/$id

    note que para remoção, não pode existir nenhum usuario ligado com ela.

    Para cadastrar uma nova:

        POST /api/city

        namespace = city.create

    Para atualizar uma existente:

        PUT /api/city/$id

        namespace = city.update


    Campos:


        $namespace.state_id    = int
        $namespace.name          = string
        $namespace.name_url      = string, opcional

        $namespace.latitude      = double, opcional, se nao enviado, é encontrado pelo google
        $namespace.longitude     = double, opcional, se nao enviado, é encontrado pelo google

        Todos os seguintes são string e opcionais:

        $namespace.summary

        $namespace.telefone_prefeitura
        $namespace.endereco_prefeitura
        $namespace.bairro_prefeitura
        $namespace.cep_prefeitura
        $namespace.email_prefeitura
        $namespace.nome_responsavel_prefeitura

*   Redes

    Redes são utilizadas para agrupar determinadas cidades e separar a
    visualização dos dados em diferentes dominios.

    Cada rede obrigatoriamente precisa de um dominio e de uma instituição.

    --------

    Para listar elas:

        GET /api/network

    Para pegar detalhes da mesma:

        GET /api/network/$id

    Para remover

        DELETE /api/network/$id

    note que para remoção, não pode existir nenhum usuario ligado com ela.

    Para cadastrar uma nova:

        POST /api/network

        namespace = network.create

    Para atualizar uma existente:

        PUT /api/network/$id

        namespace = network.update


    Campos:

        $namespace.institute_id  = int
        $namespace.domain_name   = string

        $namespace.name          = string
        $namespace.name_url      = string, opcional




