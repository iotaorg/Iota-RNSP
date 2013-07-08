Clonar valores
==================

Um usuario com cidade pode copiar valor da mesma cidade de outra instituição.

O usuario atual = usuario da API_KEY. é nele que o valor vai ser clonado.

O usuario fonte = usuário que será fonte para os dados copiados.

# consultando diferenças

Para verificar a diferença entre os usuarios, envie um GET:

?variables=id1,id2,id3...idn
?institute_id=id

O institute_id não pode ser o mesmo que o usuario logado, pois não faz sentido copiar os dados de você mesmo.

    GET "/api/user/$mov/clone_variable?variables=20,19,18&institute_id=1"

    {
        checkbox       :  {
            19:  {
                2010-01-01:  1
            },
            20:  {
                2010-01-01:  1,
                2011-01-01:  0
            }
        },
        periods        :  [
            [0] "2010-01-01",
            [1] "2011-01-01"
        ],
        variables_names:  {
            19:  "PopulaÃ§Ã£o total",
            20:  "PopulaÃ§Ã£o rural e urbana"
        }
    }

O primeiro do hash `checkbox` é o variable_id, o segunto é o periodo. Se o valor for 1, o valor não existe no usuario atual,
se o valor for 0, o valor já existe no usuario atual.

## CLONANDO

    POST "/api/user/$mov/clone_variable",
        [
            'period1'       => '2010-01-01',
            'variable:19_1' => '1',
            'variable:20_1' => '1',
            'institute_id'  => 1
        ]


Cada campo do post começando com "period" deve seguir de um número e o valor é o periodo que esse representa.

Cada campo começando com variable: deve seguir do variable_id + "_" + número do periodo que ele representa.

Todo campo enviado será clonado e os dados atuais do usuarios serão apagados, caso existam.


Mais exemplos de posts:

    POST "/api/user/$mov/clone_variable",
        [
            'period1'       => '2010-01-01',
            'period2'       => '2011-01-01',
            'period10'       => '2001-01-01',
            'variable:19_1' => '1',
            'variable:20_1' => '1',
            'variable:30_10' => '1',
            'institute_id'  => 1
        ]


    POST "/api/user/$mov/clone_variable",
        [
            'period1'       => '2010-01-01',
            'period2'       => '2010-01-01',
            'period3'       => '2011-01-01',
            'variable:19_1' => '1',
            'variable:20_2' => '1',
            'variable:20_3' => '1',
            'institute_id'  => 1
        ]

Retorna:

    {
        clones          :  {
            19:  {
                clone_values:  0
            },
            20:  {
                clone_values:  1
            }
        },
        message         :  "successfully cloned",
        number_of_clones:  1
    }


Número total de clones e numero de clones por variavel.