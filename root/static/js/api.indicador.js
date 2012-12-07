var indicador_data;
var historico_data;
var variaveis_data = [];

$(document).ready(function(){
	
	function loadCidadeDataIndicador(){
		$.ajax({
			type: 'GET',
			dataType: 'json',
			url: api_path + '/api/public/user/$$id'.render({
							id: userID
					}),
			success: function(data, textStatus, jqXHR){
				cidade_data = data;
				if (typeof(cidade_data.usuario.files.logo_movimento) != undefined){
					$("#top .content").append("<div class='logo-movimento'><img src='$$logo_movimento' alt='' /></div>".render({logo_movimento: cidade_data.usuario.files.logo_movimento}));
				}
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
				showIndicadorData();
				loadHistoricoData();
			},
			error: function(data){
				console.log("erro ao carregar informações do indicador");
			}
		});
	}
	
	function formataFormula(formula,variables){
		var operators_caption = {"+":"+"
						,"-":"-"
						,"(":"("
						,")":")"
						,"/":"÷"
						,"*":"×"
						,"CONCATENAR ":"[ ]"
						};
	
		var new_formula = formula;
		$.each(variables,function(index,value){
			var pattern = "\\$"+variables[index].id;
			var re = new RegExp(pattern, "g");
			new_formula = new_formula.replace(re,variables[index].name);
		});
		
		$.each(operators_caption,function(index,value){
			new_formula = new_formula.replace(index,"&nbsp;" + value + "&nbsp;");
		});
		
		return new_formula;
	}
	
	function showIndicadorData(){
		loadBreadCrumb();
		$("#indicador-dados .profile .title").html(indicador_data.name);
		$("#indicador-dados .profile .explanation").html(indicador_data.explanation);
		$("#indicador-dados .profile .dados .tabela").empty();
		$("#indicador-dados .profile .dados .tabela").append("<tr class='item'><td class='label'>Fórmula:</td><td class='valor'>$$dado</td></tr>".render({dado: formataFormula(indicador_data.formula,variaveis_data)}));
		if (indicador_data.goal_source){
			var fonte_meta = "<br /><span class='goal-explanation'>Fonte: $$dado</span>".render({dado: indicador_data.goal_source});
		}else{
			var fonte_meta = "";
		}
		if (indicador_data.goal){
			$("#indicador-dados .profile .dados .tabela").append("<tr class='item'><td class='label'>Referência de Meta:</td><td class='valor'>$$dado $$fonte_meta</td></tr>".render(
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
				$("#indicador-grafico .title a.link").attr("href","/"+role.replace("_","")+"/"+indicador_data.name_url+"/?view=graph&graphs="+userID);


				showHistoricoData();
			},
			error: function(data){
				console.log("erro ao carregar série histórica");
			}
		});
	}
	
	function showHistoricoData(){
	
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
			var source_values;
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
						source_values = historico_data.rows[index].valores[index2].source;
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
		}
		$("#indicador-historico .table .content-fill").append(history_table);
		
		if (goal_values){
			if (source_values){
				var source = "<br /><span class='source'>Fonte: $$dado</span>".render({dado: source_values});
			}else{
				var source = "";
			}
			$("#indicador-dados .profile .dados .tabela").append("<tr class='item'><td class='label'>Meta:</td><td class='valor'>$$dado $$source</td></tr>".render({dado: goal_values, source: source}));
		}
		
		if (observations_values){
			$("#indicador-dados .profile .dados .tabela").append("<tr class='item'><td class='label'>Observações:</td><td class='valor'>$$dado</td></tr>".render({dado: observations_values}));
		}
		
		showGrafico();
		
	}
	
	function showGrafico(){
		if (dadosGrafico.dados.length > 0){
			$("#indicador-grafico").fadeIn();
			$.carregaGrafico("main-graph");	
		}
	}

	if (ref == "indicador"){
		loadCidadeDataIndicador();
	}
	
});
