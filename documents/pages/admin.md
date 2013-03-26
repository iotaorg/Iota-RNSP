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
* Unidade de medidas
* Eixos


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
Estes usuarios administradores precisam estar ligados com uma rede [`network_id`] pois serão administradores delas.

Administradores não necessariamente precisam de uma cidade. Tais dados não serão utilizados, eu acho.

Os usuarios que esses administradores precisam ter uma instituição, campo `institute_id`;




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

* __public__: indicador compartilhado entre todos os usuarios
* __private__: indicador visivel apenas um usuário (o proprio)
* __country__: indicador visivel para os usuarios de um pais
* __restrict__: indicador visivel apenas para os usuarios selecionados.

Caso seja `visibility_level=private`, e estiver logado com um usuario `superadmin`
será necessário informar qual é o usuário e enviar o user-id do admin no campo `$namespace.visibility_user_id`

Caso seja `visibility_level=private`, e estiver logado com um usuario `admin`, é sempre ele mesmo.
Caso seja `visibility_level=country`, envie junto o campo `$namespace.visibility_country_id`;
Caso seja `visibility_level=restrict`, é nessario cadastrar cada um dos usuarios:

    POST /api/indicator/$id/user_visibility

Com o campo:

    indicator.user_visibility.create.user_id = int

Para listar, alem de vir junto com o proprio indicador, pode utilizar

    GET /api/indicator/$id/user_visibility

e como sempre, o detalhe (que nesse caso só tem a hora de criação)

    GET /api/indicator/$id/user_visibility/$id

Então lembre-se que nesse caso, como ficaria muito chato de criar isso pois nao teria o /$indicator_id
você pode enviar então no `POST /api/indicator` o campo `$namespace.visibility_users_id=123,134,321,345`
enviando a lista dos usuarios separados por virgula.

No update, caso esse campo seja enviado, vai ocorrer a troca de todos os antigos pelos novos.

Portanto, todos os campos que o `POST /api/indicator` pode receber são:

    $namespace.name                                                     string
    $namespace.name_url                                                 string, opcional

    $namespace.formula                                                  string

    $namespace.goal                                                     float
    $namespace.goal_explanation                                         string
    $namespace.goal_source                                              string
    $namespace.goal_operator                                            "<", "<=", ">", ">=", "="

    $namespace.axis_id                                                  int

    $namespace.source                                                   string
    $namespace.explanation                                              string
    $namespace.tags                                                     string

    $namespace.chart_name           (nao utilizado nem esta na tela)
    $namespace.sort_direction       (nao utilizado nem esta na tela)

    $namespace.observations                                             string

    $namespace.variety_name                                             string
    $namespace.indicator_type                                           "normal" ou "varied"

    $namespace.all_variations_variables_are_required                    boolean
    $namespace.dynamic_variations                                       boolean

    $namespace.summarization_method (nao utilizado / nao existe na tela, todos são 'sum')

    $namespace.visibility_level                 = "public", "private", "restrict" ou "country"
    $namespace.visibility_users_id              = int separados por virgula
    $namespace.visibility_country_id            = int
    $namespace.visibility_user_id               = int

Existem os mesmos itens para o atualizar:

`POST /api/indicador/$id` com namespace = `indicator.update`;


E para criar um indicador:

`POST /api/indicador` com namespace = `indicator.create`

Para apagar:

    `DELETE /api/indicador/$id`

Para listar:

    `GET /api/indicador`

Para detalhar:

    `GET /api/indicador/$id`

Exemplo do detalhe de um indicador com visibility_level=restrict:

    {
        all_variations_variables_are_required:  1,
        axis                                 :  {
            id  :  1,
            name:  "Governança"
        },
        axis_id                              :  1,
        chart_name                           :  "pie",
        created_at                           :  "2013-03-26T02:40:56",
        created_by                           :  {
            id  :  1,
            name:  "superadmin"
        },
        dynamic_variations                   :  undef,
        explanation                          :  "explanation",
        formula                              :  "5 + $101",
        goal                                 :  undef,
        goal_explanation                     :  undef,
        goal_operator                        :  ">=",
        goal_source                          :  "@fulano",
        indicator_roles                      :  "_prefeitura",
        indicator_type                       :  "normal",
        name                                 :  "Foo Bar",
        name_url                             :  "foo-bar",
        network_configs                      :  [],
        observations                         :  "lala",
        period                               :  "weekly",
        restrict_to_users                    :  [
            [0] 4,
            [1] 5,
            [2] 6,
            [3] 7
        ],
        sort_direction                       :  undef,
        source                               :  "me",
        summarization_method                 :  "sum",
        tags                                 :  "you,me,she",
        variable_type                        :  "int",
        variety_name                         :  undef,
        visibility_country_id                :  undef,
        visibility_level                     :  "restrict",
        visibility_user_id                   :  undef
    }

`restrict_to_users` são os ids dos usuarios que podem utilizar este indicador.







