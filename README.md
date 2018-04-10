
# Iota - Uma plataforma para gerenciamento de indicadores

O aplicativo é uma plataforma que permite a criação dos indicadores, com o objetivo de facilitar o compartilhamento dos dados para visualização, comparação e re-utilização deles através de padrões de tecnologias abertos.

Ele foi criado inicialmente para atender ao "Programa Cidades Sustentaveis" uma parceria da Rede Nossa São Paulo,
Instituto Ethos de Empresas e Responsabilidade Social e Rede Social Brasileira por Cidades Justas e Sustentáveis.

[Consulte o site do Iota!](http://iotaorg.github.io/Iota-RNSP/)


[![Build Status](https://secure.travis-ci.org/iotaorg/Iota-RNSP.png?branch=master)](https://travis-ci.org/iotaorg/Iota-RNSP)

## Wiki

[Você pode consultar a wiki para saber mais detalhes](https://github.com/eokoe/Iota/wiki)


> [02 Iota Como instalar uma cópia no linux](https://github.com/AwareTI/Iota/wiki/Iota---Como-instalar-uma-cópia-no-linux)


[Existe um grupo para desenvolvedores no Google Groups](https://groups.google.com/forum/embed/?place=forum/iota-devs&showsearch=true&showpopout=true&showtabs=false#!forum/iota-devs)

[E um grupo para os usuários](https://groups.google.com/forum/embed/?place=forum/iota-users&showsearch=true&showpopout=true&showtabs=false#!forum/iota-users)


institute metaconfig options:

```
{
  # se o upload de prestação de contas é pra ficar ou nao ligado
  "prestar_contas": 1,

  # se é pra renomear os campos de meta para ODS
  "ods": 1,

   # se é pra esconder o campo fonte do indicador
  "hide_indicator_source": 1,

  # se é pra esconder o campo fonte da variavel
  "hide_variable_source": 1,

  # se é pra esconder o apelido no admin, gerando a url sozinha
  "hide_cognomen": 1,

  // se é pra mostrar o campo short_name da variavel (admin)
  show_variable_short_name

  // se é pra mostrar o campo order da variavel
  show_variable_order

  # se tem programa de metas habilitado
  "prog_meta": 1,

  # nome template se for usar uma custom
  "template": "infancia",

  # se só tiver 1 cidade, colocar o prefixo
  "menu_indicators_prefix": "/br/SP/sao-paulo",

  "best_pratice_reference_city_enabled": 1,
  "axis_aux1": "Urban95",
  "bp_axis_aux1_enabled": 1,

  "axis_aux2": "Categoria",
  "bp_axis_aux2_enabled": 0,

  "axis_aux3": "ODS",
  "bp_axis_aux3_enabled": 1
}
```

## Programa Cidades Sustentaveis

Uma grande rede de organizações da sociedade civil está aproveitando as
eleições municipais de 2012 para colocar a sustentabilidade na agenda da
sociedade, dos partidos políticos e dos candidatos. Neste sentido foi lançado
o Programa Cidades Sustentáveis que oferece aos candidatos uma agenda completa
de sustentabilidade urbana, um conjunto de indicadores associados a esta
agenda, enriquecida por casos exemplares nacionais e internacionais como
referências a serem perseguidas pelos gestores públicos municipais. O programa
é complementado por uma campanha que tenta sensibilizar os eleitores a
escolher a sustentabilidade como critério de voto e os candidatos a adotar a
agenda da sustentabilidade.

O Programa Cidades Sustentáveis tem o objetivo de sensibilizar, mobilizar e
oferecer ferramentas para que as cidades brasileiras se desenvolvam de forma
econômica, social e ambientalmente sustentável.
São grandes os desafios e, para sermos exitosos em ações que contribuam com a
sustentabilidade, será necessário o envolvimento de cidadãos, organizações
sociais, empresas e governos.

### Compromissos

Os(as) candidatos(as) a cargos executivos podem confirmar seu engajamento com
o desenvolvimento sustentável assinando a Carta Compromisso. Com isso, os
signatários eleitos deverão estar dispostos a promover a Plataforma Cidades
Sustentáveis em suas cidades e a prestar contas das ações desenvolvidas e dos
avanços alcançados por meio de relatórios, revelando a evolução dos
indicadores básicos relacionados a cada eixo.

### Indicadores

Indicadores são importantes instrumentos para o planejamento de cidades mais
sustentáveis, e para desenvolvimento, execução e avaliação de políticas
públicas. Neste processo, é fundamental fixar metas de resultados e promover a
participação da sociedade civil como corresponsável pelas decisões tomadas nas
cidades.
O Programa Cidades Sustentáveis reúne mais de 300 indicadores gerais atrelados
aos eixos da Plataforma, escolhidos em um processo de construção coletivo.

Para aqueles gestores públicos interessados em assinar a Carta Compromisso,
foi desenvolvido também um relatório de prestação de contas padrão baseado em
tais indicadores. O conjunto com 100 indicadores básicos é apenas um ponto de
partida de um processo inaugurado com o lançamento do Programa Cidades
Sustentáveis.

Para as cidades com menos de 50 mil habitantes é sugerido um número
diferenciado de indicadores. E, para aquelas que desejarem avançar nesse
processo de monitoramento de políticas públicas em prol da sustentabilidade,
os indicadores gerais podem ser incorporados aos básicos.

### Licença

The GNU General Public License v3.0

### Desenvolvimento de software para apoio

Este software tem como objetivo ser a plataforma de apoio para que estas
informações sejam disponibilizadas em dados abertos.

Autores

- Thiago Rondon <thiago@aware.com.br>
- Renato Santos <renato@aware.com.br>
- Henry Shinohara <shin@aware.com.br>




