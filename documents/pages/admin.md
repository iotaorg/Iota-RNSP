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


### Preferencias [instituição]

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

### Países

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


### Estados

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

### Cidades

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

### Redes

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



### Administradores

Cadastro de administradores, que são usuarios com roles = `admin`.
Estes usuarios precisam estar ligados com uma rede [`network_id`] pois serão administradores delas.

Eles não necessariamente precisam de uma cidade. Tais dados não serão utilizados, eu acho.


--------

Para listar eles, você precisa filtrar pelo roles=admin, se não vai acabar listando todos os usuarios (inclusive o proprio superadmin)

    GET /api/user

Para pegar detalhes do mesmo:

    GET /api/user/$id

Para remover

    DELETE /api/user/$id

Remover um usuario na verdade apenas desativa ele.
Ainda vamos ver uma melhor forma de manipular os usuarios inativos.
No momento, para liberar a rede, faça uma atualização com `network_id=null` antes de apagar.

Para cadastrar uma nova:

    POST /api/user

    namespace = user.create

Para atualizar uma existente:

    PUT /api/user/$id

    namespace = user.update


Campos:

    $namespace.network_id  = int
    $namespace.roles       = string, deve-se enviar "admin" para criar um administrador.

    $namespace.name        = string
    $namespace.email       = string, unico

    $namespace.city_id     = int, opcional

    Os seguintes campos eu acho que não são necessarios no cadastro do administrador,
    mas valem para o cadastro do usuario *comum*.

    $namespace.nome_responsavel_cadastro  = string, opcional
    $namespace.estado                     = string, opcional
    $namespace.telefone                   = string, opcional
    $namespace.email_contato              = string, opcional
    $namespace.telefone_contato           = string, opcional
    $namespace.cidade                     = string, opcional
    $namespace.bairro                     = string, opcional
    $namespace.cep                        = string, opcional
    $namespace.endereco                   = string, opcional

    $namespace.city_summary               = string, opcional


Os dados de endereço são referentes ao endereço do cadastro.
O campo *city_summary* é utilziado na home page do usuário.



### Indicadores

A tela do indicadores continua exatamente igual a que existe hoje, porém, o campo `indicator_roles` nao vai mais existir.

No lugar dele, deve-se enviar `visibility_level` com um dos seguintes valores:

    * public: indicador compartilhado entre todos os usuarios
    * private: indicador visivel apenas um usuário (o proprio)
    * contry: indicador visivel para os usuarios de um pais
    * restrict: indicador visivel apenas para os usuarios selecionados.

Caso seja `visibility_level=private`, e estiver logado com um usuario `superadmin` será necessário informar qual é o usuário.
Caso seja `visibility_level=private`, e estiver logado com um usuario `admin`, é sempre ele mesmo.


