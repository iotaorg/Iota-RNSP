Administração do SuperAdmin
==================

Visão geral
----------

* Preferências
* Páginas
* Variáveis Básicas
* Editar Valores
* Indicadores
* Grupos de Indicadores


Detalhes
-------


### Preferencias

Parte igual já tem hoje, e mais um pedaço para subir um CSS caso a instituicao do usuario tenha permissao para `can_use_custom_css=1`

estou colocando os dados da institute junto com o retorno do usuario.

POST /api/user/$id/arquivo/custom.css


### Páginas

Se a instituicao do usuario logado tiver `can_use_custom_pages=1` então, tem q liberar um menu para cadastrar menu/paginas.


POST /api/menu

campos:

    menu.create.page_id
    menu.create.title
    menu.create.position
    menu.create.menu_id

o campo menu_id só pode ser outro id menu. No máximo 1 nivel, ou seja, se o $menu_id do destino tem q ser null.

title = titulo do menu

position = ordem

page_id = para gerar o link para a pagina. pode/deve ser null se o menu_id existir.


POST /api/page

campos:

    page.create.published_at (yyyy-mm-dd hh-mm-ss)
    page.create.title
    page.create.title_url
    page.create.content

Se nao enviar o title_url ele gera isso. E o published_at e nao enviar, publica na hora.

menu e paginas esperar eu fechar isso melhor.

Tanto menu como page tem o update com `/api/page/$id` e `/api/menu/$id` e list/get.


### Editar valores

Se a instituicao do usuario logado tiver `users_can_edit_value=1`


### Editar valores

Se a instituicao do usuario logado tiver `users_can_edit_value=1`,

lembrando de desativar o editar na hora de fazer o cadastro tambem.


