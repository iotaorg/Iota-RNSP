Boas praticas
==================

Visão geral
----------


Cada usuário [cidade] pode cadastrar várias boas praticas, associadas a um unico eixo e com vários eixos secundários.


Campos disponiveis:


    axis_id       opcional,  inteiro
    name          opcional,  texto
    name_url      opcional,  texto
    description   opcional,  texto
    methodology   opcional,  texto
    goals         opcional,  texto
    schedule      opcional,  texto
    results       opcional,  texto
    contatcts     opcional,  texto
    sources       opcional,  texto
    tags          opcional,  texto
    institutions_involved opcional,  texto


Create:

    POST '/api/best_pratice',
        [
            'best_pratice.create.name'   => 'FooBar',
            'best_pratice.create.description' => 'xx',
            'best_pratice.create.axis_id' => '2',
        ]

Para adicionar um ou mais eixos secundarios:

    POST '/api/best_pratice/$id/axis',
        [
            'best_pratice.axis.create.axis_id' => 1,
        ]


Para atualizar, apagar, ou detalhes, utilize:

    [GET|DELETE|POST] '/api/best_pratice/$id'

Para atualizar, o namespace é:

    POST '/api/best_pratice/$id',
        [
            'best_pratice.update.name'   => 'Zum',
        ]

Campos nao enviados/em branco são ignorados.

Para remover um campo secundário:

    DELETE '/api/best_pratice/$id/axis/$id2'

onde `$id` é o ID retornado no list ('GET /api/best_pratice/$id/axis/`) ou no detalhe do best_pratice.axis:

    GET '/api/best_pratice/$id'

    {
        axis                 :  [
            [0] {
                axis_id:  1,
                id     :  3
            },
            ...
        ],
        axis_id              :  2, < esse é o principal >
        contatcts            :  '',
        description          :  '',
        goals                :  '',
        id                   :  6,
        institutions_involved:  '',
        methodology          :  '',
        name                 :  "teste com",
        results              :  '',
        schedule             :  '',
        sources              :  '',
        tags                 :  '',
        user_id              :  1
    }


A URL para listar os indicadores na WEB é

    /<$pais>/<$estado>/<$cidade>/boas-praticas



