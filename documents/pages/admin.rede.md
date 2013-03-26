Administração do Admin
==================

Visão geral
----------

* Preferencias
** Editar dados (senha/email/nome)
** Upload de CSS
** Editar menus
** Editar paginas
* Usuários
* Países
* Estados
* Cidades
* Unidade de medidas
* Eixos
* Editar valores
* Indicadores

Tem bem mais menus, talvez seja melhor pensar em outra forma de organizar isso.


Detalhes
-------


* Preferencias

parte de editar os dados igual ao de hoje,

parte do upload do CSS / menu e paginas esperar eu fechar isso melhor.



* Usuários

igual ao de hoje


* Países

igual ao superadmin

* Estados

igual ao superadmin

* Cidades

igual ao superadmin

* Unidade de medidas

igual ao superadmin

* Eixos

igual ao superadmin

* Editar valores

igual ao de hoje



### Indicadores

Além de ter uma tela igual ao do superadmin, quando estiver logado como admin, tem que deixar ele administrar os
indicadores que são mais importantes para a rede dele.

Poder ser um simples checkbox na tela de criar/editar os indicadores, "Aparecer na home" depois a gente muda o nome.

Quando ele estiver marcado, é necessário fazer um request para gravar essa configuração,
que é válida para a rede inteira.

Como é uma configuração, não tem conceito de criar/atualizar, é sempre sobreescrever se não existir:

POST /api/indicator/$indicator_id/network_config/$network_id

Campos:

        'indicator.network_config.upsert.unfolded_in_home' => 1

Lembrando de enviar 0 se estiver atualizando o indicador e o checkbox estiver desmarcado.

Na criação, não é necessário cadastrar com valor 0, vai ter o mesmo efeito.

Em cada detalhe do `GET /api/indicator/$id` vem com as configurações das redes:

    ... demais campos ...
    network_configs: [
            [0] {
                network_id      :  1,
                unfolded_in_home:  1
            },
            [1] {
                network_id      :  2,
                unfolded_in_home:  0
            },
            ...
        ],


E no `GET /api/public/user/$user_id/indicator`:
    \ {
        resumos:  {
            'nome do eixo':  {
                weekly:  {
                    datas      :  [...],
                    indicadores:  [
                        [0] {
                            ...
                            name_url      :  "temperatura-maxima-da-semana-sp",
                            network_config:  {
                                unfolded_in_home:  0
                            },
                            valores       :  [...]
                        }
                    ]
                },
                ...
            }
        }
    }
