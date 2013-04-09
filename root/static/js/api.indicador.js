var indicador_data;
var historico_data;
var variaveis_data = [];
var data_vvariables = [];
var cidade_uri;
var cidade_data;

$(document).ready(function(){

	$.loadCidadeDataIndicador = function(){
		$.ajax({
			type: 'GET',
			dataType: 'json',
			url: api_path + '/api/public/user/$$id'.render({
							id: userID
					}),
			success: function(data, textStatus, jqXHR){
				cidade_data = data;
				loadIndicadorData();
			},
			error: function(data){
				console.log("erro ao carregar informações da cidade");
			}
		});
	}

	function loadIndicadorData(){
		$.ajax({
			type: 'GET',
			dataType: 'json',
			url: api_path + '/api/public/user/$$id/indicator/$$indicator_id'.render({
							id: userID,
							indicator_id: indicadorID
					}),
			success: function(data, textStatus, jqXHR){
				indicador_data = data;
				indicadorDATA = data;
				loadVariaveisData();
			},
			error: function(data){
				console.log("erro ao carregar informações do indicador");
			}
		});
	}

	function loadVariaveisData(){
		$.ajax({
			type: 'GET',
			dataType: 'json',
			url: api_path + '/api/public/user/variable',
			success: function(data, textStatus, jqXHR){
				$.each(data.variables, function(index,value){
					variaveis_data.push({"id":data.variables[index].id,"name":data.variables[index].name});
				});
				loadVVariaveisData();
			},
			error: function(data){
				console.log("erro ao carregar informações do indicador");
			}
		});
	}

	function loadVVariaveisData(){

		data_vvariables = [];
		$.ajax({
			type: 'GET',
			dataType: 'json',
			url: api_path + '/api/public/user/indicator/variable',
			success: function(data, textStatus, jqXHR){
				$.each(data.variables, function(index,value){
					data_vvariables.push({"id":data.variables[index].id,"name":data.variables[index].name});
				});
				showIndicadorData();
				loadHistoricoData();
			}
		});

	}

	function formataFormula(formula,variables,vvariables){
		var operators_caption = {"+":"+"
						,"-":"-"
						,"(":"("
						,")":")"
						,"/":"÷"
						,"*":"×"
						,"CONCATENAR":""
						};

		var new_formula = formula;

		variables.sort(function (a, b) {
			return b.id - a.id;
		});

		$.each(variables,function(index,value){
			var pattern = "\\$"+variables[index].id;
			var re = new RegExp(pattern, "g");
			new_formula = new_formula.replace(re,variables[index].name);
		});

		$.each(operators_caption,function(index,value){
			new_formula = new_formula.replace(index,"&nbsp;" + value + "&nbsp;");
		});

		if (vvariables){
			vvariables.sort(function (a, b) {
				return b.id - a.id;
			});
			$.each(vvariables,function(index,value){
				var pattern = "\\#"+vvariables[index].id;
				var re = new RegExp(pattern, "g");
				new_formula = new_formula.replace(re,vvariables[index].name);
			});
		}

		return new_formula;
	}

	function showIndicadorData(){

        $("#indicador-dados .profile .title").html(indicador_data.name);

        $("h1").text(indicador_data.name + ' - ' + cidade_data.cidade.name + ', ' + cidade_data.cidade.uf);
		$("#indicador-dados .profile .explanation").html(indicador_data.explanation);
		$("#indicador-dados .profile .dados .tabela").empty();
		if (indicador_data.formula.indexOf("CONCATENAR") < 0){
			$("#indicador-dados .profile .dados .tabela")
                .append("<dt>Fórmula:</dt><dd>$$dado</dd>"
                .render({dado: formataFormula(indicador_data.formula,variaveis_data,data_vvariables)}));
		}
        var fonte_meta = "";
		if (indicador_data.goal_source){
			fonte_meta = indicador_data.goal_source;
		}
		if (indicador_data.goal_explanation){
			$("#indicador-dados .profile .dados .tabela")
            .append('<dt>Referência de Meta:</dt><dd>$$dado<blockquote><small><cite title="Fonte: $$fonte_meta">$$fonte_meta</cite></small></blockquote></dd>'
                .render(
				{
					dado: indicador_data.goal_explanation,
					fonte_meta: fonte_meta
				}));
		}
	}

	function loadHistoricoData(){
		$.ajax({
			type: 'GET',
			dataType: 'json',
			url: api_path + '/api/public/user/$$id/indicator/$$indicator_id/variable/value'.render({
							id: userID,
							indicator_id: indicadorID
					}),
			success: function(data, textStatus, jqXHR){
				historico_data = data;
				$("#indicador-historico span.cidade").html(cidade_data.cidade.name);
				$("#indicador-grafico span.cidade").html(cidade_data.cidade.name);
				$("#indicador-grafico .title a.link").attr("href","/"+indicador_data.name_url+"/?view=graph&graphs="+userID);

				showHistoricoData();
			},
			error: function(data){
				console.log("erro ao carregar série histórica");
			}
		});
	}

	function showHistoricoData(){
        var source_values = [];

		if (historico_data.rows){
			var history_table = "<table class='history'><thead><tr><th>Período</th>";

			var headers = [];//corrige ordem do header
			$.each(historico_data.header,function(titulo, index){
				headers[index] = titulo;
			});

			$.each(headers, function(index,value){
				history_table += "<th class='variavel'>$$variavel</th>".render({variavel:value});
			});
			history_table += "<th class='formula_valor'>Valor da Fórmula</th>";
			history_table += "</tr><tbody>";

			dadosGrafico = {"dados": [], "labels": []};

			var goal_values;
			var observations_values;

			var valores = [];
			$.each(historico_data.rows, function(index,value){
				history_table += "<tr><td class='periodo'>$$periodo</td>".render({periodo: convertDateToPeriod(historico_data.rows[index].valid_from,indicador_data.period)});
				dadosGrafico.labels.push(convertDateToPeriod(historico_data.rows[index].valid_from,indicador_data.period));
				$.each(historico_data.rows[index].valores, function(index2,value2){
					history_table += "<td class='valor'>$$valor</td>".render({
							valor: $.formatNumber(historico_data.rows[index].valores[index2].value, {format:"#,###", locale:"br"}),
							data: convertDate(historico_data.rows[index].valores[index2].value_of_date,"T")
					});
					if (historico_data.rows[index].valores[index2].source){
						source_values.push(historico_data.rows[index].valores[index2].source);
					}
					if (historico_data.rows[index].valores[index2].observations){
						observations_values = historico_data.rows[index].valores[index2].observations;
					}
				});
				if(historico_data.rows[index].formula_value != null && historico_data.rows[index].formula_value != "-"){
					history_table += "<td class='formula_valor'>$$formula_valor</td>".render({formula_valor: $.formatNumber(historico_data.rows[index].formula_value, {format:"#,##0.###", locale:"br"})});
				}else{
					history_table += "<td class='formula_valor'>-</td>";
				}
				history_table += "</tr></tbody>";
				if (historico_data.rows[index].goal){
					goal_values = historico_data.rows[index].goal;
				}

				if (historico_data.rows[index].formula_value != "-" && historico_data.rows[index].formula_value != "" && historico_data.rows[index].formula_value != null){
					valores.push(parseFloat(historico_data.rows[index].formula_value).toFixed(3));
				}else{
					valores.push(null);
				}

			});
			history_table += "</table>";
			dadosGrafico.dados.push({id: userID, nome: cidade_data.cidade.name, valores: valores, data: cidade_data, show: true});
		}else{
			var history_table = "<table class='history'><thead><tr><th>nenhum registro encontrado</th></tr></thead></table>";
            dadosGrafico.dados = [];
		}
		$("#indicador-historico .table .content-fill").html(history_table);

		if ((goal_values) && goal_values.trim() != ""){
			if (goal_values.toLowerCase().indexOf("fonte:") > 0){
				goal_values = goal_values.replace("fonte:","Fonte:");
                goal_values = goal_values.replace("Fonte:",'<blockquote><small><cite title="Fonte da meta">') + "</cite></small></blockquote>";
			}
			$("#indicador-dados .profile .dados .tabela").append("<dt>Meta:</dt><dd>$$dado</dd>".render({dado: goal_values}));
		}

		if (source_values.length > 0){

			var source_values_unique = [];
			$.each(source_values, function(i, el){
			    if($.inArray(el, source_values_unique) === -1) source_values_unique.push(el);
			});
            $("#indicador-dados .profile .dados .tabela").append("<dt>Fontes do Indicador:</dt><dd><ul><li>$$dado</li></ul></dd>".render({dado: source_values_unique.join("</li><li>")}));
		}
		if ((observations_values) && observations_values.trim() != ""){
			$("#indicador-dados .profile .dados .tabela").append("<dt>Observações:</dt><dd>$$dado</dd>".render({dado: observations_values}));
		}

		showGrafico();

	}

	function showGrafico(){

		if (dadosGrafico.dados.length > 0){
			$("#indicador-grafico").fadeIn();
			$.carregaGrafico("main-graph");
		}else{
            $("#indicador-grafico").fadeOut();

        }
	}

	if (ref == "indicador"){
		$.loadCidadeDataIndicador();
	}

});
