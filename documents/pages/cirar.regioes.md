Regioes
==================

Uma regiao tem nome, uma cidade e um level.

O level pode ser 2, caso seja uma subprefeitura. ou 3, quando é uma regiao dentro de outra regiao, no caso, a regiao level 3 é um distrito.

Regioes de level = 2 podem receber um campo chamado *automatic_fill* para dizer que os valores dela devem ser calculados a partir da _soma_ dos valores inseridos pelas regioes level 3.

### Criar uma regiao


    POST  '/api/city/:id/region',
    [
        api_key                          => 'test',
        'city.region.create.name'        => 'a region',
        'city.region.create.description' => 'with no description',
    ]

Tabem pode receber os campos:

    city.region.create.automatic_fill => boolean



### Pegar uma regiao


    GET '/api/city/:id/region/:id'
    {
        automatic_fill:  0,
        city          :  {
            name    :  "Foo Bar",
            name_uri:  "foo-bar",
            pais    :  "br",
            uf      :  "SP"
        },
        depth_level   :  3,
        description   :  "description",
        name          :  "xxx",
        name_url      :  "xxx",
        upper_region  :  {
            id      :  133,
            name    :  "a region",
            name_url:  "a-region"
        }
    }

*upper_region* pode ser nulo quando a regiao tem *depth_level* = 2;


### listar regioes


    GET '/api/city/:id/region'
    {
        regions:  [
            [0] {
                automatic_fill:  0,
                city_id       :  1476,
                created_at    :  "2013-05-16 08:37:44.526826",
                created_by    :  2,
                depth_level   :  2,
                description   :  "with no description",
                id            :  135,
                name          :  "a region",
                name_url      :  "a-region",
                upper_region  :  undef,
                url           :  "http://localhost/api/city/1476/region/135"
            },
            [1] {
                automatic_fill:  0,
                city_id       :  1476,
                created_at    :  "2013-05-16 08:37:44.526826",
                created_by    :  2,
                depth_level   :  3,
                description   :  "description",
                id            :  136,
                name          :  "foobar",
                name_url      :  "foobar",
                upper_region  :  135,
                url           :  "http://localhost/api/city/1476/region/136"
            }
        ]
    }

### Atualizando regioes

Envia-se os campos alterados assim como na criação, porem .update.:

    POST '/api/city/:id/region/:id'

    'city.region.update.name' => 'xxx',
    'city.region.update.upper_region' => $id,
    'city.region.update.description' => 'foo',
    'city.region.update.automatic_fill' => 0,

Campos não enviados ou nulos são ignorados.



### Apagando regioes:

Para apagar uma região, ela não pode ter dados preenchidos, nem outars sub-regioes

    DELETE '/api/city/:id/region/:id'

