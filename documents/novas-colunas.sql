/* Indicador
nova coluna pra salvar quem pode adicionar dados no indicador.



   indicator_roles aceita os valores: '_prefeitura', '_movimento' combinações deles com virgula
      '_prefeitura,_movimento' tem o mesmo efeito de '_movimento,_prefeitura'
*/


ALTER TABLE indicator
  ADD COLUMN indicator_roles character varying;


