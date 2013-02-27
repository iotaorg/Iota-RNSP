if (!String.prototype.render) {
	String.prototype.render = function(args) {
		var copy = this + '';
		for (var i in args) {
			copy = copy.replace(RegExp('\\$\\$' + i, 'g'), args[i]);
		}
		return copy;
	};
}

$.extend({
	getUrlVars: function(){
		var vars = [], hash;
		var hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&');
		for(var i = 0; i < hashes.length; i++){
			hash = hashes[i].split('=');
			vars.push(hash[0]);
			vars[hash[0]] = hash[1];
		}
		return vars;
	},
	getUrlVar: function(name){
		return $.getUrlVars()[name];
	},
	convertDate: function(date,splitter){
		var date_tmp = date.split(splitter);
		var date = date_tmp[0];
		var time = date_tmp[1];

		var date_split = date.split("-");

		return date_split[2] + "/" + date_split[1] + "/" + date_split[0];

	},
	convertDatetoBd: function(date,splitter){
		var date_tmp = date.split(splitter);
		var date = date_tmp[0];
		var time = date_tmp[1];

		var date_split = date.split("/");

		return date_split[2] + "/" + date_split[1] + "/" + date_split[0];
	},
	convertDateToPeriod: function(date,period){
		if (period == "yearly"){
			return date.split("-")[0];
		}else if (period == "monthly"){
			return date.split("-")[1] + "/" + date.split("-")[0];
		}
	}
});

$.xhrPool = [];
$.xhrPool.abortAll = function() {
    $(this).each(function(idx, jqXHR) {
        jqXHR.abort();
    });
    $.xhrPool.length = 0
};

$.ajaxSetup({
    beforeSend: function(jqXHR) {
        $.xhrPool.push(jqXHR);
    },
    complete: function(jqXHR) {
        var index = $.xhrPool.indexOf(jqXHR);
        if (index > -1) {
            $.xhrPool.splice(index, 1);
        }
    }
});

$(document).ready(function() {

	var user_info;
	//lista roles
	var roles = {"admin":"Administrador Geral",
				 "user":"Prefeitura/Movimento da Rede",
				 "app":"Aplicativos"
				}
	//lista tipos variaveis
	var variable_types = {"int":"Inteiro",
						  "str":"Alfanumérico",
						  "num":"Valor"};
	var variable_periods = {"monthly":"Mensal",
						  "yearly":"Anual",
						  "trimestral":"Trimestral",
						  "semiannual":"Semestral"
						  };

	var goal_operators = {"":"",
						  ">":"maior que",
						  ">=":"maior ou igual a",
						  "=":"igual a",
						  "menor ou igual a":"<=",
						  "menor que":"<"
						  };

	var sort_directions = {"greater value":"MAIOR valor, melhor classificação",
						  "lowest value":"MENOR valor, melhor classificação"
						  };

	var estados = {"AC":"Acre",
				  "AL":"Alagoas",
				  "AM":"Amazonas",
				  "AP":"Amapá",
				  "BA":"Bahia",
				  "CE":"Ceará",
				  "DF":"Distrito Federal",
				  "ES":"Espírito do Santo",
				  "GO":"Goiás",
				  "MA":"Maranhão",
				  "MG":"Minas Gerais",
				  "MS":"Mato Grosso do Sul",
				  "MT":"Mato Grosso",
				  "PA":"Pará",
				  "PB":"Paraíba",
				  "PE":"Pernambuco",
				  "PI":"Piauí",
				  "PR":"Paraná",
				  "RJ":"Rio de Janeiro",
				  "RN":"Rio Grande do Norte",
				  "RO":"Rondônia",
				  "RR":"Roraima",
				  "RS":"Rio Grande do Sul",
				  "SC":"Santa Catarina",
				  "SE":"Sergipe",
				  "SP":"São Paulo",
				  "RJ":"Rio de Janeiro",
				  "RS":"Rio Grande do Sul",
				  "TO":"Tocantins"
						  };
	var cidades_prefeitos = [];

	var click_editor = false;

	var qtip_input = {
		 position: {
					  corner: {
						 tooltip: 'leftMiddle', // Use the corner...
						 target: 'rightMiddle' // ...and opposite corner
					  }
				   },
		style: {
		  border: {
			 width: 2,
			 radius: 4
		  },
		  padding: 5,
		  textAlign: 'left',
		  tip: true, // Give it a speech bubble tip with automatic corner detection
		  name: 'cream' // Style it according to the preset 'cream' style
	   },
	   show: {
		  when: 'focus'
	   },
	   hide: {
		  when: {
				event: 'unfocus'
		  }
	   }
	};
	var qtip_editor = {
		 position: {
					  corner: {
						 tooltip: 'leftTop', // Use the corner...
						 target: 'rightTop' // ...and opposite corner
					  }
				   },
		style: {
		  border: {
			 width: 2,
			 radius: 4
		  },
		  padding: 5,
		  textAlign: 'left',
		  tip: true, // Give it a speech bubble tip with automatic corner detection
		  name: 'cream' // Style it according to the preset 'cream' style
	   },
	   hide: {
		  when: {
				event: 'unfocus'
		  }
	   }
	};

	$.fn.setWarning = function(){
		var args = arguments[0];
		$(this).hide();
		$(this).empty();
		$(this).html("<div>"+args.msg+"</div>");
		$(this).show("slow");
	};
	$.fn.clearWarning = function(){
		$(this).hide();
		$(this).html("");
	};

	var findCidadePrefeito = function(city_id){
		var retorno = "";
		for (i = 0; i < cidades_prefeitos.length; i++){
			if (cidades_prefeitos[i].id == city_id){
				 var retorno = cidades_prefeitos[i].prefeito_id;
			}
		}
		return retorno;
	}

	var findCidadeMovimento = function(city_id){
		var retorno = "";
		for (i = 0; i < cidades_prefeitos.length; i++){
			if (cidades_prefeitos[i].id == city_id){
				 var retorno = cidades_prefeitos[i].movimento_id;
			}
		}
		return retorno;
	}

	var resetDashboard = function(){
		$("#aviso").setWarning({msg: ""});
		$("#user-info").remove();
		$("#menu ul li").remove();
		$("#menu ul").append("<li class='selected'>LOGIN</li>");
		setTitleBar();
	};
	var resetWarnings = function(){
		$("#aviso").empty();
		$(".form-aviso").empty();
	};

	$("#form-login form").submit(function(e){
		e.preventDefault();
		resetWarnings();
		sendLogin();
	});

	var sendLogin = function(){
		args = [{name: "user.login.email",value: $("#form-login #usuario").val()},
				{name: "user.login.password",value: $("#form-login #senha").val()}
				];

		$.ajax({
			type: 'POST',
			dataType: 'json',
			url: '/api/login',
			data: args,
			success: function(data,status,jqXHR){
				switch(jqXHR.status){
					case 200:
						resetWarnings();
						$.cookie("user.login",data.login,{ expires: 1 });
						$.cookie("user.id",data.id,{ expires: 1 });
						$.cookie("key",data.api_key,{ expires: 1 });
						$("#dashboard #form-login").hide();
						location.hash = "!/dashboard";
						break;
				}
			},
			error: function(data){
				switch(data.status){
					case 400:
						$("#aviso").setWarning({msg: "Erro: $$codigo".render({
									codigo: $.parseJSON(data.responseText).error
									})
						});
						break;
				}
			}
		});
	};

	/*monta titleBar*/

	var setTitleBar = function(){
		var pagina = getUrlSub();
		var option = $.getUrlVar("option");

		if (pagina == ""){
			pagina = "login";
		}

		$("#header-title .title").empty();;
		$("#header-title .description").empty();
		if(titleBarContent[pagina+","+option]){
			$("#header-title .title").html(titleBarContent[pagina+","+option]["title"]);
			if(titleBarContent[pagina+","+option]["tip"] != ""){
				$("#header-title .description").html(titleBarContent[pagina+","+option]["tip"]);
			}
		}else if(titleBarContent[pagina]){
			$("#header-title .title").html(titleBarContent[pagina]["title"]);
			if(titleBarContent[pagina]["tip"] != ""){
				$("#header-title .description").html(titleBarContent[pagina]["tip"]);
			}
		}
		if ($("#header-title .title").html() != ""){
			var d = document.title;
			document.title = d.substring(0, d.indexOf(' - ')) + ' - ' + $("#header-title .title").html();
		}
	}

	var buildList = function(args){
		var url = args.url;
		var headers = args.headers;
		var fields = args.fields;
		var data = args.data;
		var button = args.button;

		var newlist = "";

		if (button == "undefined" || button == true){
			newlist += buildButton("Adicionar","button-add","button-add");
		}

		newlist += "<table class='results'>";
		newlist += "<thead>";
		newlist += "<tr>";
		for (var key in headers){
			newlist += "<th>" +  headers[key] + "</th>";
		}
		newlist += "<th class='buttons'></th>";
		newlist += "</tr>";
		newlist += "</thead>";

		newlist += "<tbody>";

		$.each(data,function(index,value){
			newlist += "<tr>";
			for (var key in fields){
				newlist += "<td>" + data[index][fields[key]] + "</td>";
			}
			newlist += "<td class='buttons'><a href='$$hash?option=edit&url=$$url' class='icone edit' title='editar' alt='editar'>editar</a><a href='$$hash?option=delete&url=$$url' class='icone delete' title='apagar' alt='apagar'>apagar</a></td>".render({
					hash: "#!/"+getUrlSub(),
					url: data[index]["url"]
			});;
			newlist += "</tr>";
		});
		if (data.length == 0){
			newlist += "<td colspan='20'><span class='noresults'>Nenhum resultado encontrado</span></td>";
		}
		newlist += "<tbody>";
		newlist += "</table>";
		return newlist;
	};
	var buildDataTable = function(args,table_id,button_add,add_class){
		var headers = args.headers;

		var newlist = "";

		if (button_add == undefined || button_add == true){
			newlist += buildButton("Adicionar","button-add","button-add");
		}
		if (add_class == undefined || add_class == null){
			add_class = "";
		}
		if (table_id == undefined || table_id == null){
			table_id = "results";
		}

		newlist += "<table id='" + table_id + "' class='" + add_class + "'>";
		newlist += "<thead>";
		newlist += "<tr>";
		for (var key in headers){
			newlist += "<th>" +  headers[key].replace("_","&nbsp;") + "</th>";
		}
		newlist += "</tr>";
		newlist += "</thead>";

		newlist += "<tbody>";
		newlist += "</tbody>";
		newlist += "</table>";
		return newlist;

	};

	var DTdesenhaBotoes = function(){
		$("#results td.botoes").each( function(){
			if ($(this).find("a").length <= 0){
				var url = $(this).html();
				$(this).html( "<a href='$$hash?option=edit&url=$$url' class='icone edit' title='editar' alt='editar'>editar</a><a href='$$hash?option=delete&url=$$url' class='icone delete' title='apagar' alt='apagar'>apagar</a>".render({
						hash: "#!/"+getUrlSub(),
						url: url
				}));
			}
		});
	}

	var DTdesenhaBotaoVariavel = function(){
		$("#results td.botoes").each( function(){
			if ($(this).find("a").length <= 0){
				var url = $(this).html();
				$(this).html( "<a href='$$hash?option=edit&url=$$url' class='icone edit' title='Adicionar Valor' alt='editar'>adicionar valor</a>".render({
						hash: "#!/"+getUrlSub(),
						url: "/api/variable/" + url
				}));
			}
		});
	}

	var buildForm = function(form_args,title){
		var newform = "<div class='form'>";
		if (title){
			newform += "<div class='title'>$$title</div>".render({title: title});
		}
		newform += "<div class='form-aviso'></div>";
		for (i = 0; i < form_args.length; i++){
			if (form_args[i].type == "div"){
				newform += "<div class='div'></div>";
			}else{
				if (form_args[i].class == undefined) form_args[i].class = "";
				newform += "<div class='field $$class'>".render({class: form_args[i].class});
				if (form_args[i].label != ""){
					var separator = ":";
				}else{
					var separator = "";
				}
				newform += "<div class='label'>$$label$$separator</div>".render({label: form_args[i].label,separator: separator});
				var newinput;
				newform += "<div class='input'>";
				for (j = 0; j < form_args[i].input.length; j++){
					var input_args = form_args[i].input[j].split(",");
					switch(input_args[0]){
						case "text":
						case "password":
							newinput = "<input type='$$type' name='$$id' id='$$id' class='$$class'>".render({
									type: input_args[0],
									id: input_args[1],
									class: input_args[2]
									})
							break;
						case "select":
							newinput = "<select name='$$id' id='$$id' class='$$class'></select>".render({
									id: input_args[1],
									class: input_args[2]
									})
							break;
						case "radio":
							newinput = "<input type='radio' name='$$id' id='$$id' class='$$class' />".render({
									id: input_args[1],
									class: input_args[2]
									})
							break;
						case "checkbox":
							newinput = "<input type='checkbox' name='$$id' id='$$id' class='$$class' />".render({
									id: input_args[1],
									class: input_args[2]
									})
							break;
						case "textarea":
							newinput = "<textarea name='$$id' id='$$id' class='$$class'></textarea>".render({
									id: input_args[1],
									class: input_args[2]
									})
							break;
						case "textlabel":
							newinput = "<div class='$$class' id='$$id'></div>".render({
									id: input_args[1],
									class: input_args[2]
									})
							break;
					}
					newform += newinput;
				}
				newform += "</div>";
				newform += "<div class='clear'></div>";
				newform += "</div>";
			}
		}
		newform += "<div class='clear'></div>";
		newform += "</div>";
		newform += "<div class='clear'></div>";

		newform += "<div class='form-buttons'><a href='javascript: void(0);' class='botao-form' ref='enviar'>Enviar</a>";
		newform += "<a href='javascript: void(0);' class='botao-form' ref='cancelar'>Cancelar</a></div>";

		return newform;
	};

	var buildButton = function(label,classname,id){
		var new_button = "<a href='javascript: void(0);' class='$$class' id='$$id'>$$label</a>".render({
			class: classname,
			label: label,
			id: id
		});
		return new_button;
	};

	var buildVariableHistory = function(var_id){
		$("#dashboard-content .content div.historico").html("carregando");
		$.ajax({
			type: 'GET',
			dataType: 'json',
			url: '/api/user/$$userid/variable?api_key=$$key'.render({
					key: $.cookie("key"),
					userid: $.cookie("user.id")
					}),
			success: function(data, textStatus, jqXHR){
				var data_variables = new Array();
				$.each(data.variables, function(index,value){
					if (String(data.variables[index].variable_id) == getIdFromUrl($.getUrlVar("url"))){
						data_variables.push({"id":data.variables[index].variable_id,"name":data.variables[index].name,"period":data.variables[index].period,"values":data.variables[index].values});
					}
				});

				//mostra historico

				var history_table = "<div class='title'>Série Histórica</div><div class='historic-content'>";
				history_table += "<table class='history'><thead><tr><th>Período</th><th>Valor</th><th></th></tr></thead><tbody>";
				$.each(data_variables[0].values, function(index,value){
					history_table += "<tr value-id='$$value_id'><td class='periodo'>$$periodo</td>".render({
								periodo: $.convertDateToPeriod(data_variables[0].values[index].valid_from,data_variables[0].period),
								value_id: data_variables[0].values[index].id
								});
					history_table += "<td class='valor'>$$valor</td><td class='edit'><a href='javascript: void(0);' value-id='$$value_id' class='edit'>editar</a>&nbsp;<a href='javascript: void(0);' value-id='$$value_id' class='delete'>apagar</a></td>".render({
								valor: data_variables[0].values[index].value,
								data: $.format.date(data_variables[0].values[index].value_of_date,"dd/MM/yyyy"),
								value_id: data_variables[0].values[index].id
					});
					history_table += "</tr></tbody>";
				});
				if (data_variables[0].values.length <= 0){
					history_table += "<tr><td class='no-data' colspan='10'>nenhum registro</td></tr>";
				}
				history_table += "</table>";
				history_table += "</div>";

				$("#dashboard-content .content div.historico").empty();
				$("#dashboard-content .content div.historico").append(history_table);
				$("#dashboard-content .content div.historic table").width($("#dashboard-content .content").find(".form").width());
				$("div.historico .title").click(function(){
					$(this).parent().find(".historic-content").toggle();
				});
				$("table.history a.edit").click(function(){

					// carrega Historico para editar

					$("table.history tbody tr").removeClass("selected");
					$(this).parent().parent().addClass("selected");
					var value_selected = $(this);

					$.ajax({
						type: 'GET',
						dataType: 'json',
						url: '/api/variable/$$var_id/value/$$value_id?api_key=$$key'.render({
								key: $.cookie("key"),
								var_id: getIdFromUrl($.getUrlVar("url")),
								value_id: $(value_selected).attr("value-id")
								}),
						success: function(data, textStatus, jqXHR){
							$("#dashboard-content .content .form").find("input#value").val(data.value);
							if (data_variables[0].period == "yearly"){
								$("#dashboard-content .content .form").find("#value_of_date").val($.format.date(data.value_of_date,"yyyy-MM-dd"));
								$("#dashboard-content .content .form").find("#value_of_date").attr("disabled","disabled");
							}else if (data_variables[0].period == "daily"){
								$("#dashboard-content .content .form").find("#value_of_date").val($.convertDate(data.value_of_date," "));
							}
							$("#dashboard-content .content .form").find(".title").html("Editar Valor");
							$("#dashboard-content .content .botao-form[ref='enviar']").html("Editar");
							$("#dashboard-content .content .botao-form[ref='cancelar']").html("Cancelar");
						}
					});

				});
				$("table.history a.delete").click(function(){
					var value_selected = $(this);
					deleteRegister({
						url: '/api/variable/$$var_id/value/$$value_id?api_key=$$key'.render({
								key: $.cookie("key"),
								var_id: getIdFromUrl($.getUrlVar("url")),
								value_id: $(value_selected).attr("value-id")
								}),
						redirect: false,
						call: "buildVariableHistory"
					});
				});
			}
		});
	}

	var buildIndicatorHistory = function (args){

		$.ajax({
			type: 'GET',
			dataType: 'json',
			url: '/api/indicator/$$id/variable/value?api_key=$$key'.render({
					key: $.cookie("key"),
					id: args.id
					}),
			success: function(data, textStatus, jqXHR){
				if (data.header && data.rows != undefined){
					var history_table = "<div class='title' title='mostrar/esconder Histórico'>Série Histórica</div><div class='historic-content'>";
					history_table += "<table class='history'><thead><tr><th>Período</th>";
					$.each(data.header, function(index,value){
						history_table += "<th class='variavel'>$$variavel</th>".render({variavel:index});
					});
					history_table += "<th class='formula_valor'>Valor da Fórmula</th>";
					history_table += "</tr></thead><tbody>";
					$.each(data.rows, function(index,value){
						history_table += "<tr><td class='periodo'>$$periodo</td>".render({periodo: $.convertDateToPeriod(data.rows[index].valid_from,args.period)});
						$.each(data.rows[index].valores, function(index2,value2){
							history_table += "<td class='valor' title='$$data'>$$valor</td>".render({
									valor: data.rows[index].valores[index2].value,
									data: $.convertDate(data.rows[index].valores[index2].value_of_date,"T")
							});
						});
						history_table += "<td class='formula_valor'>$$valor</td>".render({
								valor: data.rows[index].formula_value
						});
						history_table += "</tr></tbody>";
					});
					history_table += "</table>";
					history_table += "</div>";
				}else{
					var history_table = "<div class='title' title='mostrar/esconder Histórico'>Série Histórica</div><div class='historic-content'><table class='history'><thead><tr><th>nenhum registro encontrado</th></tr></thead></table></div>";
				}
				$(args.target).empty();
				$(args.target).append(history_table);
				$(args.target).find(".title").click(function(){
					$(this).parent().find(".historic-content").toggle();
				});
			}
		});

	}

	var deleteRegister = function(params){
		$.confirm({
			'title': 'Confirmação',
			'message': 'Você irá excluir permanentemente esse registro.<br />Continuar?',
			'buttons': {
				'Sim': {
					'class'	: '',
					'action': function(){
						$.ajax({
							type: 'DELETE',
							dataType: 'json',
							url: params.url,
							success: function(data,status,jqXHR){
								switch(jqXHR.status){
									case 204:
										resetWarnings();
										$("#aviso").setWarning({msg: "Cadastro apagado com sucesso."});
										if (params.redirect == undefined || params.redirect == true){
											location.hash = "#!/"+getUrlSub();
										}
										if (params.call != undefined){
											eval(params.call+"();");
										}
										break;
								}
							},
							error: function(data){
								switch(data.status){
									case 200:
										break;
									default:
										$("#aviso").setWarning({msg: "Erro: ($$codigo)".render({
													codigo: data.status
													})
										});
										if (params.redirect == undefined || params.redirect == true){
											location.hash = "#!/"+getUrlSub();
										}
										break;
								}
							}
						});
					}
				},
				'Não'	: {
					'class'	: '',
					'action': function(){
						if (params.redirect == undefined || params.redirect == true){
							location.hash = "#!/"+getUrlSub();
						}
					}
				}
			}
		});
	}

	var getUrlSub = function(){
		var hash = location.hash;
		var url_split = hash.split("#!");
		if (url_split.length > 1){
			var url_split_sub = url_split[1].split("/");
			if (url_split_sub.length > 1){
				var url_sub = url_split_sub[1];
			}else{
				var url_sub = url_split[1];
			}

			var url_split_sub = url_sub.split("?");
			if (url_split_sub.length > 1){
				var url_sub = url_split_sub[0];
			}else{
				var url_sub = url_split_sub;
			}

		}else{
			var url_sub = "";
		}
		return url_sub;
	};

	var getIdFromUrl = function(url){
		if (url == undefined) return undefined;
		var split_url = url.split("/");
		if (split_url.length > 0){
			return split_url[split_url.length-1];
		}else{
			return null;
		}
	}

	$.confirm = function(params){
		if($("#dialog-overlay").length > 0){
			return false;
		}

		var buttonHTML = '';
		$.each(params.buttons,function(name,obj){
			buttonHTML += '<a href="javascript:;" class="button-default '+obj['class']+'">'+name+'</a>';
			if(!obj.action){
				obj.action = function(){};
			}
		});

		var confirmWindow = "<div id='dialog-overlay'>";
		confirmWindow += "<div id='dialog-box'>";
		confirmWindow += "<div id='dialog-content'>";
		confirmWindow += "<div id='dialog-title'>$$title</div>".render({title: params.title});
		confirmWindow += "<div id='dialog-message'>$$message</div>".render({message: params.message});
		confirmWindow += "<div id='dialog-buttons'>$$buttons</div>".render({buttons: buttonHTML});
		confirmWindow += "</div></div></div>";

		$(confirmWindow).hide().appendTo("body").fadeIn();

		var buttons = $('#dialog-box .button-default'), i = 0;

		$.each(params.buttons,function(name,obj){
			buttons.eq(i++).click(function(){
				obj.action();
				$.confirm.hide();
				return false;
			});
		});
	};
	$.confirm.hide = function(){
		$('#dialog-overlay').fadeOut(function(){
			$(this).remove();
		});
	}

	var loadCidades = function(){
		cidades_prefeitos = [];
		$.ajax({
			type: 'GET',
			dataType: 'json',
			url: '/api/city?api_key=$$key'.render({
							key: $.cookie("key")
					}),
			success: function(data, textStatus, jqXHR){
				$.each(data.citys, function(index,value){
					cidades_prefeitos.push({"id":data.citys[index].id,"prefeito_id":data.citys[index].prefeito_id, "movimento_id":data.citys[index].movimento_id});
				});

			},
			error: function(data){
				$("#aviso").setWarning({msg: "Erro ao carregar ($$codigo)".render({
							codigo: $.parseJSON(data.responseText).error
						})
				});
			}
		});
	}

	var buildLogin = function(){
		resetDashboard();
		$("#dashboard #form-login").show();
	}

	var formataFormula = function(formula,variables){
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
			new_formula = new_formula.replace("$"+variables[index].id,variables[index].name);
		});

		$.each(operators_caption,function(index,value){
			new_formula = new_formula.replace(index,value);
		});

		return new_formula;
	}

	var getVariablesFromFormula = function(formula){
		var indicator_variables = formula.replace(/[^0-9.\$]/g," ").match(/\s\$[^\s]*|^\$[^\s]*/gi);
		for (i = 0; i < indicator_variables.length; i++){
			indicator_variables[i] = indicator_variables[i].replace(" ","");
			indicator_variables[i] = indicator_variables[i].replace("$","");
		}
		return indicator_variables;
	}

	var buildUserInterface = function(){
		if ($.cookie("key") != null && $.cookie("key") != ""){
			$.ajax({
				type: 'GET',
				dataType: 'json',
				url: '/api/user/$$userid?api_key=$$key'.render({
						userid: $.cookie("user.id"),
						key: $.cookie("key")
				}),
				success: function(data,status,jqXHR){
					switch(jqXHR.status){
						case 200:
							user_info = data;
							if (user_info.roles[0]){
								var user_roles = (user_info.roles[0]) ? " (" + roles[user_info.roles[0]] + ")" : "";
								var info_content = "Usuário: " + user_info.name;
								if($("#user-info").length == 0){
									$("#top .content").append("<div id='user-info'>" + info_content + "</div>");
								}else{
									$("#top #user-info").html(info_content);
								}
								buildMenu();
								setTitleBar();
								buildContent();
								break;
							}else{
								$.confirm({
									'title': 'Aviso',
									'message': 'Erro ao carregar informações do Usuário.',
									'buttons': {
										'Ok': {
											'class'	: '',
											'action': function(){
												$.cookie("user.id",null);
												$.cookie("key",null);
												resetDashboard();
												location.hash = "";
											}
										}
									}
								});
							}
					}
				},
				error: function(data){
					switch(data.status){
						case 400:
							$("#aviso").setWarning({msg: "Erro: ($$codigo)".render({
										codigo: $.parseJSON(data.responseText).error
										})
							});
							break;
						case 403:
							$.confirm({
								'title': 'Aviso',
								'message': 'Sua sessão expirou.',
								'buttons': {
									'Ok': {
										'class'	: '',
										'action': function(){
											$.cookie("user.id",null);
											$.cookie("key",null);
											resetDashboard();
											location.hash = "";
										}
									}
								}
							});
							break;
						case 500:
							$.confirm({
								'title': 'Aviso',
								'message': 'Erro ao carregar informações do Usuário.',
								'buttons': {
									'Ok': {
										'class'	: '',
										'action': function(){
											$.cookie("user.id",null);
											$.cookie("key",null);
											resetDashboard();
											location.hash = "";
										}
									}
								}
							});
							break;
					}
				}
			});
		}else{
			$.cookie("user.id",null);
			$.cookie("key",null);
			resetDashboard();
			buildLogin();
		}
	};
	var buildMenu = function(){
		if($("#menu ul li").length > 0){
			$("#menu ul li").remove();
		}
		var menu = "<div id='menu'><ul class='menu'></ul></div>";
		$("#dashboard-content #user-info").after(menu);

		var menu_label = [];
		var menu_access = [];

		menu_label["dashboard"] = "Home";
		menu_label["users"] = "Usuários";
		menu_label["cities"] = "Cidades";
		menu_label["variable"] = "Variáveis";
		menu_label["myvariable"] = "Variáveis Básicas";
		menu_label["myindicator"] = "Indicadores";
		menu_label["indicator"] = "Indicadores";
		menu_label["tokens"] = "Tokens";
		menu_label["reports"] = "Relatórios";
		menu_label["prefs"] = "Preferências";
		menu_label["logout"] = "Logout";

		menu_access["admin"] = ["dashboard","users","cities","variable","indicator","prefs","logout"];
		menu_access["user"] = ["dashboard","myvariable","myindicator","prefs","logout"];

		$.each(menu_access[user_info.roles[0]],function(index,value){
			var menu_class = (getUrlSub() == value) ? "selected" : "";
			$("#menu").find("ul").append("<li class='$$class' ref='$$url_sub'>$$menu</li>".render({
				menu: "<a href='#!/" + value + "'>" + menu_label[value] + "</a>",
				url_sub: value,
				class: menu_class
			}));
		});
		$("#menu li a").click(function(){
			resetWarnings();
		});
	};

	var updateFormula = function(){
		var formula = "";
		$("#formula-editor .editor-content div").each(function(index,element){
			if ($(this).hasClass("f-variable")){
				formula += "$"+$(this).attr("var_id");
			}else if ($(this).hasClass("f-operator")){
				formula += $(this).attr("val");
			}else{
				formula += $(this).html();
			}
		});
		$("textarea#formula").val(formula);
	}

	var convertFormulaToCss = function(){
		var operators = ["+","-","(",")","/","*"];
		var operators_caption = {"+":"+"
						,"-":"-"
						,"(":"("
						,")":")"
						,"/":"÷"
						,"*":"×"
						,"CONCATENAR ":"[ ]"
						};
		var formula = $("textarea#formula").val();
		var formula_css = "";
		for (i = 0; i < formula.length; i++){
			if ($.inArray(formula[i],operators) >= 0){
				formula_css += "<div class='f-operator' val='$$val'>$$caption</div>".render({val:formula[i],caption:operators_caption[formula[i]]});
			}else if (formula[i] == "$"){
				var var_id = "";
				var var_caption = "";
				for (j = i+1; j < formula.length; j++){
					if ($.inArray(formula[j],operators) >= 0 || formula[j] == "$"){
						i = j - 1;
						break;
					}else{
						var_id += formula[j];
						i = j;
					}
				}
				var_caption = $("#formula-editor .variables .item[var_id='"+var_id+"']").html();
				formula_css += "<div class='f-variable' apelido='$$var_id'>$$caption</div>".render({var_id:var_id,caption:var_caption});
			}else{
				var var_input = "";
				for (j = i; j < formula.length; j++){
					if ($.inArray(formula[j],operators) >= 0 || formula[j] == "$"){
						i = j - 1;
						break;
					}else{
						var_input += formula[j];
						i = j;
					}
				}
				formula_css += "<div class='f-input'>$$caption</div>".render({caption:var_input});
			}
		}
		$("#formula-editor .editor-content").html(formula_css);
	}

	var carregaComboCidades = function(args){
		$.ajax({
			type: 'GET',
			dataType: 'json',
			url: '/api/city?api_key=$$key'.render({
							key: $.cookie("key")
					}),
			success: function(data, textStatus, jqXHR){
				if (args){
					if (args.option == "edit"){
						$.each(data.citys, function(index,value){
							if (findCidadePrefeito(data.citys[index].id) == null || findCidadeMovimento(data.citys[index].id) == null){
								$("#dashboard-content .content select#city_id").append($("<option></option>").val(data.citys[index].id).html(data.citys[index].name + " (" + data.citys[index].uf + ")"));
							}else{
								console.log(findCidadeMovimento(data.citys[index].id) + ":" + getIdFromUrl(args.city));
								if (findCidadePrefeito(data.citys[index].id) == getIdFromUrl(args.city) || findCidadeMovimento(data.citys[index].id) == getIdFromUrl(args.city)){
									$("#dashboard-content .content select#city_id").append($("<option></option>").val(data.citys[index].id).html(data.citys[index].name + " (" + data.citys[index].uf + ")"));
								}
							}
						});
						if (args.city != undefined){
							$("#dashboard-content .content select#city_id").val(getIdFromUrl(args.city));
						}
					}
				}else{
					$.each(data.citys, function(index,value){
						if (findCidadePrefeito(data.citys[index].id) == null || findCidadeMovimento(data.citys[index].id) == null){
							$("#dashboard-content .content select#city_id").append($("<option></option>").val(data.citys[index].id).html(data.citys[index].name + " (" + data.citys[index].uf + ")"));
						}
					});
				}
				$("#dashboard-content .content select#city_id").change(function(){
					var city_id = $(this).find("option:selected").val();
					var disabled = false;
					var checked = true;
					if (findCidadePrefeito($(this).find("option:selected").val()) != null){
						if ($.getUrlVar("option") == "edit"){
							if (getIdFromUrl($.getUrlVar("url")) == findCidadePrefeito($(this).find("option:selected").val())){
								$("#dashboard-content .content input#prefeito").attr("checked",true);
								$("#dashboard-content .content input#prefeito").attr("disabled",false);
							}else{
								$("#dashboard-content .content input#prefeito").attr("checked",false);
								$("#dashboard-content .content input#prefeito").attr("disabled",true);
							}
						}else{
							$("#dashboard-content .content input#prefeito").attr("checked",false);
							$("#dashboard-content .content input#prefeito").attr("disabled",true);
						}
					}else{
						$("#dashboard-content .content input#prefeito").attr("checked",false);
						$("#dashboard-content .content input#prefeito").attr("disabled",false);
					}

				});

			},
			error: function(data){
				$("#aviso").setWarning({msg: "Erro ao carregar ($$codigo)".render({
							codigo: $.parseJSON(data.responseText).error
						})
				});
			}
		});
	}

	/*MONTA TELAS*/

	$(window).hashchange( function(){
		$("#dashboard-content .content").empty();
		buildUserInterface();
	})

	var buildContent = function(){
		if ($.inArray(getUrlSub().toString(),["dashboard","users","cities","variable","myvariable","indicator","myindicator","tokens","reports","prefs"]) >= 0){
			$("#dashboard #form-login").hide();
			/*  ORGANIZATION  */
			if (getUrlSub() == "dashboard"){

			}else if (getUrlSub() == "users"){
				/*  USER  */
				loadCidades();
				if ($.getUrlVar("option") == "list" || $.getUrlVar("option") == undefined){

					var userList = buildDataTable({
							headers: ["Nome","Email","_"]
							});

					$("#dashboard-content .content").append(userList);

					$("#button-add").click(function(){
						resetWarnings();
						location.hash = "#!/" + getUrlSub() + "?option=add";
					});

					$("#results").dataTable( {
						  "oLanguage": {
										"sUrl": "js/dataTables.pt-br.txt"
										},
						  "bProcessing": true,
						  "sAjaxSource": '/api/user?api_key=$$key&content-type=application/json&columns=name,email,url,_,_'.render({
								key: $.cookie("key")
								}),
						  "aoColumnDefs": [
                        					{ "bSearchable": false, "bSortable": false, "sClass": "botoes", "sWidth": "60px", "aTargets": [ 2 ] }
                    					  ],
						   "fnDrawCallback": function(){
								DTdesenhaBotoes();
							}
					} );

				}else if ($.getUrlVar("option") == "add" || $.getUrlVar("option") == "edit"){

					var txtOption = ($.getUrlVar("option") == "add") ? "Cadastrar" : "Editar";

					var newform = [];

					newform.push({label: "Nome", input: ["text,name,itext"]});
					newform.push({label: "Email", input: ["text,email,itext"]});
					newform.push({label: "Senha", input: ["password,password,itext"]});
					newform.push({label: "Confirmar Senha", input: ["password,password_confirm,itext"]});
					newform.push({label: "Nível", input: ["select,user_role,iselect"]});
					newform.push({label: "Cidade", input: ["select,city_id,iselect"], "class": "prefeitura"});
					newform.push({label: "Prefeitura?", input: ["checkbox,prefeito,icheckbox"], "class": "prefeitura"});

					var formbuild = $("#dashboard-content .content").append(buildForm(newform,txtOption));
					$(formbuild).find("div .field:odd").addClass("odd");
					$(formbuild).find(".form-buttons").width($(formbuild).find(".form").width());

					$(formbuild).find("#name").qtip( $.extend(true, {}, qtip_input, {
							content: "Importante: Nome do usuário."
					}));
					$(formbuild).find("#email").qtip( $.extend(true, {}, qtip_input, {
							content: "Importante: o Email será usado como login."
					}));
					$(formbuild).find("#name").qtip( $.extend(true, {}, qtip_input, {
							content: "Utilize letras e números e pelo menos 8 caracteres."
					}));

					$.each(roles,function(key, value){
						$("#dashboard-content .content select#user_role").append($("<option></option>").val(key).html(value));
					});

					$("#dashboard-content .content select#user_role").change(function(){
						if ($(this).find("option:selected").val() == "user"){
							$(formbuild).find("div.prefeitura").show();
						}else{
							$(formbuild).find("div.prefeitura").hide();
						}
					});

					$("#dashboard-content .content input#prefeito").attr("disabled",true);

					$("#dashboard-content .content select#city_id").append($("<option></option>").val("").html("Selecione..."));

					if ($.getUrlVar("option") == "add"){
						carregaComboCidades();
						$("#dashboard-content .content .botao-form[ref='enviar']").click(function(){
							resetWarnings();
							if ($(this).parent().parent().find("#name").val() == ""){
								$(".form-aviso").setWarning({msg: "Por favor informe o Nome"});
							}else if ($(this).parent().parent().find("#email").val() == ""){
								$(".form-aviso").setWarning({msg: "Por favor informe o Email"});
							}else if ($(this).parent().parent().find("#password").val() == ""){
								$(".form-aviso").setWarning({msg: "Por favor informe a Senha"});
							}else if ($(this).parent().parent().find("#password_confirm").val() == "" || $(this).parent().parent().find("#password_confirm").val() != $(this).parent().parent().find("#password").val()){
								$(".form-aviso").setWarning({msg: "Confirmação de senha inválida"});
							}else if ($(this).parent().parent().find("#city_id option:selected").val() == "" && $(this).parent().parent().find("#user_role option:selected").val() == "user"){
								$(".form-aviso").setWarning({msg: "Por favor informe a Cidade"});
							}else{
								args = [{name: "api_key", value: $.cookie("key"),},
										{name: "user.create.name", value: $(this).parent().parent().find("#name").val()},
										{name: "user.create.email", value: $(this).parent().parent().find("#email").val(),},
										{name: "user.create.password", value: $(this).parent().parent().find("#password").val(),},
										{name: "user.create.password_confirm", value: $(this).parent().parent().find("#password").val(),},
										{name: "user.create.role", value: $(this).parent().parent().find("#user_role option:selected").val(),},
										{name: "user.create.city_id", value: $(this).parent().parent().find("#city_id option:selected").val(),}
										];
								if ($(this).parent().parent().find("#prefeito").attr("checked")){
									args.push({name: "user.create.prefeito", value: 1});
									args.push({name: "user.create.movimento", value: 0});
								}else{
									args.push({name: "user.create.prefeito", value: 0});
									if ($(this).parent().parent().find("#user_role option:selected").val() == "user"){
										args.push({name: "user.create.movimento", value: 1});
									}
								}
								$("#dashboard-content .content .botao-form[ref='enviar']").hide();
								$.ajax({
									type: 'POST',
									dataType: 'json',
									url: '/api/user',
									data: args,
									success: function(data,status,jqXHR){
										$("#aviso").setWarning({msg: "Cadastro efetuado com sucesso.".render({
													codigo: jqXHR.status
													})
										});
										location.hash = "#!/"+getUrlSub();
									},
									error: function(data){
										switch(data.status){
											case 400:
												$("#aviso").setWarning({msg: "Erro ao cadastrar. ($$codigo)".render({
															codigo: $.parseJSON(data.responseText).error
															})
												});
												break;
										}
										$("#dashboard-content .content .botao-form[ref='enviar']").show();
									}
								});
							}
						});
					}else if ($.getUrlVar("option") == "edit"){
						$.ajax({
							type: 'GET',
							dataType: 'json',
							url: $.getUrlVar("url") + "?api_key=$$key".render({
										key: $.cookie("key")
								}),
							success: function(data,status,jqXHR){
								switch(jqXHR.status){
									case 200:
										$(formbuild).find("input#name").val(data.name);
										$(formbuild).find("input#email").val(data.email);
										if ($.cookie("organization.id") == null){
											if (data.organization != undefined){
												$(formbuild).find("select#organization_id").val(getIdFromUrl(data.organization));
											}
										}
										$(formbuild).find("select#user_role").val(data.roles[0]);
										if (data.roles[0] == "user"){
											$(formbuild).find("div.prefeitura").show();
										}else{
											$(formbuild).find("div.prefeitura").hide();
										}
										carregaComboCidades({"option":"edit", "city": data.city});
										if (data.city != undefined){
											if (findCidadePrefeito(getIdFromUrl(data.city)) == getIdFromUrl($.getUrlVar("url"))){
												$(formbuild).find("input#prefeito").attr("disabled",false);
												$(formbuild).find("input#prefeito").attr("checked",true);
											}else{
												$(formbuild).find("input#prefeito").attr("disabled",false);
											}
										}
										break;
								}
							},
							error: function(data){
								switch(data.status){
									case 400:
										$(".form-aviso").setWarning({msg: "Erro: ($$codigo)".render({
													codigo: $.parseJSON(data.responseText).error
													})
										});
										break;
								}
							}
						});

						$("#dashboard-content .content .botao-form[ref='enviar']").click(function(){
							resetWarnings();
							if ($(this).parent().parent().find("#name").val() == ""){
								$(".form-aviso").setWarning({msg: "Por favor informe o Nome"});
							}else if ($(this).parent().parent().find("#email").val() == ""){
								$(".form-aviso").setWarning({msg: "Por favor informe o Email"});
							}else if ($(this).parent().parent().find("#password_confirm").val() != $(this).parent().parent().find("#password").val()){
								$(".form-aviso").setWarning({msg: "Confirmação de senha inválida"});
							}else if ($(this).parent().parent().find("#city_id option:selected").val() == "" && $(this).parent().parent().find("#user_role option:selected").val() == "user"){
								$(".form-aviso").setWarning({msg: "Por favor informe a Cidade"});
							}else{
								args = [{name: "api_key", value: $.cookie("key"),},
										{name: "user.update.name", value: $(this).parent().parent().find("#name").val()},
										{name: "user.update.email", value: $(this).parent().parent().find("#email").val(),},
										{name: "user.update.role", value: $(this).parent().parent().find("#user_role option:selected").val(),},
										{name: "user.update.city_id", value: $(this).parent().parent().find("#city_id option:selected").val(),}
										];
								if ($(this).parent().parent().find("#prefeito").attr("checked")){
									args.push({name: "user.update.prefeito", value: 1});
								}else{
									args.push({name: "user.update.prefeito", value: 0});
									if ($(this).parent().parent().find("#user_role option:selected").val() == "user"){
										args.push({name: "user.update.movimento", value: 1});
									}
								}

								if ($(this).parent().parent().find("#password").val() != ""){
									args.push({name: "user.update.password", value: $(this).parent().parent().find("#password").val(),},
										{name: "user.update.password_confirm", value: $(this).parent().parent().find("#password").val(),});
								}
								$("#dashboard-content .content .botao-form[ref='enviar']").hide();
								$.ajax({
									type: 'POST',
									dataType: 'json',
									url: $.getUrlVar("url"),
									data: args,
									success: function(data, textStatus, jqXHR){
										$("#aviso").setWarning({msg: "Cadastro editado com sucesso.".render({
													codigo: jqXHR.status
													})
										});
										location.hash = "#!/"+getUrlSub();
										$("#dashboard-content .content .botao-form[ref='enviar']").show();
									},
									error: function(data){
										$(".form-aviso").setWarning({msg: "Erro ao editar. ($$erro)".render({
													erro: $.parseJSON(data.responseText).error
													})
										});
										$("#dashboard-content .content .botao-form[ref='enviar']").show();
									}
								});
							}
						});
					}
					$("#dashboard-content .content .botao-form[ref='cancelar']").click(function(){
						resetWarnings();
						history.back();
					});
				}else if ($.getUrlVar("option") == "delete"){
					deleteRegister({url:$.getUrlVar("url") + "?api_key=$$key".render({
													key: $.cookie("key")
											})});
				}
			}else if (getUrlSub() == "cities"){
				/*  CIDADES  */
				if ($.getUrlVar("option") == "list" || $.getUrlVar("option") == undefined){

					var userList = buildDataTable({
							headers: ["Nome","Estado","_"]
							});

					$("#dashboard-content .content").append(userList);

					$("#button-add").click(function(){
						resetWarnings();
						location.hash = "#!/" + getUrlSub() + "?option=add";
					});

					$("#results").dataTable( {
						  "oLanguage": {
										"sUrl": "js/dataTables.pt-br.txt"
										},
						  "bProcessing": true,
						  "sAjaxSource": '/api/city?api_key=$$key&content-type=application/json&columns=name,uf,url,_,_'.render({
								key: $.cookie("key")
								}),
						  "aoColumnDefs": [
                        					{ "bSearchable": false, "bSortable": false, "sClass": "botoes", "sWidth": "60px", "aTargets": [ 2 ] }
                    					  ],
						   "fnDrawCallback": function(){
								DTdesenhaBotoes();
							}
					} );

				}else if ($.getUrlVar("option") == "add" || $.getUrlVar("option") == "edit"){

					var txtOption = ($.getUrlVar("option") == "add") ? "Cadastrar" : "Editar";

					var newform = [];

					newform.push({label: "Nome", input: ["text,name,itext"]});
					newform.push({label: "Estado", input: ["select,uf,iselect"]});

					var formbuild = $("#dashboard-content .content").append(buildForm(newform,txtOption));
					$(formbuild).find("div .field:odd").addClass("odd");
					$(formbuild).find(".form-buttons").width($(formbuild).find(".form").width());

					$(formbuild).find("#name").qtip( $.extend(true, {}, qtip_input, {
							content: "Importante: Nome da Cidade."
					}));

					$.each(estados,function(key, value){
						$("#dashboard-content .content select#uf").append($("<option></option>").val(key).html(value));
					});

					if ($.getUrlVar("option") == "add"){
						$("#dashboard-content .content .botao-form[ref='enviar']").click(function(){
							resetWarnings();
							if ($(this).parent().parent().find("#name").val() == ""){
								$(".form-aviso").setWarning({msg: "Por favor informe o Nome"});
							}else if ($(this).parent().parent().find("#uf option:selected").val() == ""){
								$(".form-aviso").setWarning({msg: "Por favor informe o Estado"});
							}else{
								args = [{name: "api_key", value: $.cookie("key"),},
										{name: "city.create.name", value: $(this).parent().parent().find("#name").val()},
										{name: "city.create.uf", value: $(this).parent().parent().find("#uf option:selected").val()}
										];
								$("#dashboard-content .content .botao-form[ref='enviar']").hide();
								$.ajax({
									type: 'POST',
									dataType: 'json',
									url: '/api/city',
									data: args,
									success: function(data,status,jqXHR){
										$("#aviso").setWarning({msg: "Cadastro efetuado com sucesso.".render({
													codigo: jqXHR.status
													})
										});
										location.hash = "#!/"+getUrlSub();
									},
									error: function(data){
										switch(data.status){
											case 400:
												$("#aviso").setWarning({msg: "Erro ao cadastrar. ($$codigo)".render({
															codigo: $.parseJSON(data.responseText).error
															})
												});
												break;
										}
										$("#dashboard-content .content .botao-form[ref='enviar']").show();
									}
								});
							}
						});
					}else if ($.getUrlVar("option") == "edit"){
						$.ajax({
							type: 'GET',
							dataType: 'json',
							url: $.getUrlVar("url") + "?api_key=$$key".render({
										key: $.cookie("key")
								}),
							success: function(data,status,jqXHR){
								switch(jqXHR.status){
									case 200:
										$(formbuild).find("input#name").val(data.name);
										$(formbuild).find("select#uf").val(data.uf);
										break;
								}
							},
							error: function(data){
								switch(data.status){
									case 400:
										$(".form-aviso").setWarning({msg: "Erro: ($$codigo)".render({
													codigo: $.parseJSON(data.responseText).error
													})
										});
										break;
								}
							}
						});

						$("#dashboard-content .content .botao-form[ref='enviar']").click(function(){
							resetWarnings();
							if ($(this).parent().parent().find("#name").val() == ""){
								$(".form-aviso").setWarning({msg: "Por favor informe o Nome"});
							}else if ($(this).parent().parent().find("#uf option:selected").val() == ""){
								$(".form-aviso").setWarning({msg: "Por favor informe o Estado"});
							}else{
								args = [{name: "api_key", value: $.cookie("key"),},
										{name: "city.update.name", value: $(this).parent().parent().find("#name").val()},
										{name: "city.update.uf", value: $(this).parent().parent().find("#uf option:selected").val(),}
										];

								$("#dashboard-content .content .botao-form[ref='enviar']").hide();
								$.ajax({
									type: 'POST',
									dataType: 'json',
									url: $.getUrlVar("url"),
									data: args,
									success: function(data, textStatus, jqXHR){
										$("#aviso").setWarning({msg: "Cadastro editado com sucesso.".render({
													codigo: jqXHR.status
													})
										});
										location.hash = "#!/"+getUrlSub();
										$("#dashboard-content .content .botao-form[ref='enviar']").show();
									},
									error: function(data){
										$(".form-aviso").setWarning({msg: "Erro ao editar. ($$erro)".render({
													erro: $.parseJSON(data.responseText).error
													})
										});
										$("#dashboard-content .content .botao-form[ref='enviar']").show();
									}
								});
							}
						});
					}
					$("#dashboard-content .content .botao-form[ref='cancelar']").click(function(){
						resetWarnings();
						history.back();
					});
				}else if ($.getUrlVar("option") == "delete"){
					deleteRegister({url:$.getUrlVar("url") + "?api_key=$$key".render({
													key: $.cookie("key")
											})});
				}
			}else if (getUrlSub() == "variable"){
				/*  VARIABLE  */
				if ($.getUrlVar("option") == "list" || $.getUrlVar("option") == undefined){

					var variableList = buildDataTable({
							headers: ["Nome","Apelido","Tipo","Data Criação","Básica","_"]
							});

					$("#dashboard-content .content").append(variableList);

					$("#button-add").click(function(){
						resetWarnings();
						location.hash = "#!/" + getUrlSub() + "?option=add";
					});

					$("#results").dataTable( {
						  "oLanguage": {
										"sUrl": "js/dataTables.pt-br.txt"
										},
						  "bProcessing": true,
						  "sAjaxSource": '/api/variable?api_key=$$key&content-type=application/json&columns=name,cognomen,type,created_at,is_basic,url,_,_'.render({
								key: $.cookie("key")
								}),
						  "aoColumnDefs": [
                        					{ "bSearchable": false, "bSortable": false, "sClass": "botoes", "sWidth": "80px", "aTargets": [ 5 ] },
                        					{ "bSearchable": false, "bSortable": false, "sClass": "center is_basic", "aTargets": [ 4 ] },
                        					{ "sClass": "center", "aTargets": [ 2 , 3, 4 ] },
											{ "fnRender": function ( oObj, sVal ) {
									        	            return variable_types[sVal];
							    	          			  }, "aTargets": [ 2 ]
											},
											{ "fnRender": function ( oObj, sVal ) {
									        	            return $.format.date(sVal,"dd/MM/yyyy HH:mm:ss");
							    	          			  }, "aTargets": [ 3 ]
											},
                    					  ],
						   "aaSorting": [[4,'asc'],[0,'asc']],
						   "fnDrawCallback": function(){
								DTdesenhaBotoes();
								$("#results td.is_basic").each( function(){
									if ($(this).html() == "1"){
										$(this).html("Sim");
									}else if ($(this).html() == "0"){
										$(this).html("Não");
									}
								});

							}
					} );

				}else if ($.getUrlVar("option") == "add" || $.getUrlVar("option") == "edit"){

					var txtOption = ($.getUrlVar("option") == "add") ? "Cadastrar" : "Editar";

					var newform = [];

					newform.push({label: "Nome", input: ["text,name,itext"]});
					newform.push({label: "Apelido", input: ["text,cognomen,itext"]});
					newform.push({label: "Explicação", input: ["textarea,explanation,itext"]});
					newform.push({label: "Tipo", input: ["select,type,iselect"]});
					newform.push({label: "Período", input: ["select,period,iselect"]});
					newform.push({label: "Fonte", input: ["text,source,itext"]});
					newform.push({label: "Variável básica", input: ["checkbox,is_basic,icheckbox"]});

					var formbuild = $("#dashboard-content .content").append(buildForm(newform,txtOption));
					$(formbuild).find("div .field:odd").addClass("odd");
					$(formbuild).find(".form-buttons").width($(formbuild).find(".form").width());

					$(formbuild).find("#name").qtip( $.extend(true, {}, qtip_input, {
							content: "Nome da variável."
					}));
					$(formbuild).find("#cognomen").qtip( $.extend(true, {}, qtip_input, {
							content: "Nome amigável/abreviado para a Variável.<br />Ex: Desnutrição infantil > Apelido: 'Desnut_Infantil' ou 'Desn.Infant'"
					}));
					$(formbuild).find("#explanation").qtip( $.extend(true, {}, qtip_input, {
							content: "Explicação breve sobre a Variável."
					}));
					$(formbuild).find("#type").qtip( $.extend(true, {}, qtip_input, {
							content: "Ex:<br />Inteiro = 10<br />Alfanumérico = Azul<br />Valor = 100,00"
					}));
					$(formbuild).find("#is_basic").qtip( $.extend(true, {}, qtip_input, {
							content: "Marcar essa opção para variáveis básicas."
					}));

					$.each(variable_types,function(key, value){
						$("#dashboard-content .content select#type").append($("<option></option>").val(key).html(value));
					});

					$.each(variable_periods,function(key, value){
						$("#dashboard-content .content select#period").append($("<option></option>").val(key).html(value));
					});

					if ($.getUrlVar("option") == "add"){
						$("#dashboard-content .content .botao-form[ref='enviar']").click(function(){
							resetWarnings();
							if ($(this).parent().parent().find("#name").val() == ""){
								$(".form-aviso").setWarning({msg: "Por favor informe o Nome"});
							}else if ($(this).parent().parent().find("#cognomen").val() == ""){
								$(".form-aviso").setWarning({msg: "Por favor informe o Apelido"});
							}else{
								args = [{name: "api_key", value: $.cookie("key"),},
										{name: "variable.create.name", value: $(this).parent().parent().find("#name").val()},
										{name: "variable.create.cognomen", value: $(this).parent().parent().find("#cognomen").val(),},
										{name: "variable.create.explanation", value: $(this).parent().parent().find("#explanation").val(),},
										{name: "variable.create.type", value: $(this).parent().parent().find("#type option:selected").val(),},
										{name: "variable.create.period", value: $(this).parent().parent().find("#period option:selected").val(),},
										{name: "variable.create.source", value: $(this).parent().parent().find("#source").val(),}
										];

								if ($(this).parent().parent().find("#is_basic").attr("checked")){
									args.push({name: "variable.create.is_basic", value: 1});
								}else{
									args.push({name: "variable.create.is_basic", value: 0});
								}

								$("#dashboard-content .content .botao-form[ref='enviar']").hide();
								$.ajax({
									type: 'POST',
									dataType: 'json',
									url: '/api/variable',
									data: args,
									success: function(data,status,jqXHR){
										$("#aviso").setWarning({msg: "Cadastro efetuado com sucesso.".render({
													codigo: jqXHR.status
													})
										});
										location.hash = "#!/"+getUrlSub();
									},
									error: function(data){
										switch(data.status){
											case 400:
												$("#aviso").setWarning({msg: "Erro ao cadastrar. ($$codigo)".render({
															codigo: $.parseJSON(data.responseText).error
															})
												});
												break;
										}
										$("#dashboard-content .content .botao-form[ref='enviar']").show();
									}
								});
							}
						});
					}else if ($.getUrlVar("option") == "edit"){
						$.ajax({
							type: 'GET',
							dataType: 'json',
							url: $.getUrlVar("url") + "?api_key=$$key".render({
										key: $.cookie("key")
								}),
							success: function(data,status,jqXHR){
								switch(jqXHR.status){
									case 200:
										$(formbuild).find("input#name").val(data.name);
										$(formbuild).find("input#cognomen").val(data.cognomen);
										$(formbuild).find("textarea#explanation").val(data.explanation);
										$(formbuild).find("select#type").val(data.type);
										$(formbuild).find("select#period").val(data.period);
										$(formbuild).find("input#source").val(data.source);
										if (data.is_basic == 1){
											$(formbuild).find("input#is_basic").attr("checked",true);
										}else{
											$(formbuild).find("input#is_basic").attr("checked",false);
										}
										break;
								}
							},
							error: function(data){
								switch(data.status){
									case 400:
										$(".form-aviso").setWarning({msg: "Erro: ($$codigo)".render({
													codigo: $.parseJSON(data.responseText).error
													})
										});
										break;
								}
							}
						});

						$("#dashboard-content .content .botao-form[ref='enviar']").click(function(){
							resetWarnings();
							if ($(this).parent().parent().find("#name").val() == ""){
								$(".form-aviso").setWarning({msg: "Por favor informe o Nome"});
							}else if ($(this).parent().parent().find("#cognomen").val() == ""){
								$(".form-aviso").setWarning({msg: "Por favor informe o Apelido"});
							}else{
								args = [{name: "api_key", value: $.cookie("key"),},
										{name: "variable.update.name", value: $(this).parent().parent().find("#name").val()},
										{name: "variable.update.cognomen", value: $(this).parent().parent().find("#cognomen").val(),},
										{name: "variable.update.explanation", value: $(this).parent().parent().find("#explanation").val(),},
										{name: "variable.update.type", value: $(this).parent().parent().find("#type option:selected").val(),},
										{name: "variable.update.period", value: $(this).parent().parent().find("#period option:selected").val(),},
										{name: "variable.update.source", value: $(this).parent().parent().find("#source").val(),},
										];
								if ($(this).parent().parent().find("#is_basic").attr("checked")){
									args.push({name: "variable.update.is_basic", value: 1});
								}else{
									args.push({name: "variable.update.is_basic", value: 0});
								}

								$("#dashboard-content .content .botao-form[ref='enviar']").hide();
								$.ajax({
									type: 'POST',
									dataType: 'json',
									url: $.getUrlVar("url"),
									data: args,
									success: function(data, textStatus, jqXHR){
										$("#aviso").setWarning({msg: "Cadastro editado com sucesso.".render({
													codigo: jqXHR.status
													})
										});
										location.hash = "#!/"+getUrlSub();
										$("#dashboard-content .content .botao-form[ref='enviar']").show();
									},
									error: function(data){
										$(".form-aviso").setWarning({msg: "Erro ao editar. ($$erro)".render({
													erro: $.parseJSON(data.responseText).error
													})
										});
										$("#dashboard-content .content .botao-form[ref='enviar']").show();
									}
								});
							}
						});
					}
					$("#dashboard-content .content .botao-form[ref='cancelar']").click(function(){
						resetWarnings();
						history.back();
					});
				}else if ($.getUrlVar("option") == "delete"){

					deleteRegister({url:$.getUrlVar("url") + "?api_key=$$key".render({
													key: $.cookie("key")
											})});
				}
			}else if (getUrlSub() == "myvariable"){
				/*  VARIABLE  */
				if ($.getUrlVar("option") == "list" || $.getUrlVar("option") == undefined){

					var variableList = buildDataTable({
							headers: ["Nome","_"]
							},null,false);

					$("#dashboard-content .content").append(variableList);

					$("#button-add").click(function(){
						resetWarnings();
						location.hash = "#!/" + getUrlSub() + "?option=add";
					});

					$.ajax({
						type: 'GET',
						dataType: 'json',
						url: '/api/user/$$userid/variable?api_key=$$key&is_basic=1'.render({
								key: $.cookie("key"),
								userid: $.cookie("user.id")
								}),
						success: function(data, textStatus, jqXHR){
							$.each(data.variables, function(index,value){
								$("#dashboard-content .content #results tbody").append($("<tr><td>$$nome</td><td>$$url</td></tr>".render({nome: data.variables[index].name,
								apelido: data.variables[index].cognomen,
								url: data.variables[index].variable_id})));
							});

							$("#results").dataTable( {
								  "oLanguage": {
												"sUrl": "js/dataTables.pt-br.txt"
												},
								  "aoColumnDefs": [
													{ "bSearchable": false, "bSortable": false, "sClass": "botoes", "sWidth": "60px", "aTargets": [ 1 ] },
												  ],
								   "fnDrawCallback": function(){
										DTdesenhaBotaoVariavel();
									}
							} );
						},
						error: function(data){
							$("#aviso").setWarning({msg: "Erro ao carregar ($$codigo)".render({
										codigo: $.parseJSON(data.responseText).error
									})
							});
						}
					});

				}else if ($.getUrlVar("option") == "edit"){

					var txtOption = "Adicionar Valor";

					$.ajax({
						type: 'GET',
						dataType: 'json',
						url: $.getUrlVar("url") + "?api_key=$$key".render({
									key: $.cookie("key")
							}),
						success: function(data,status,jqXHR){
							if (jqXHR.status == 200){

								var newform = [];

								newform.push({label: "Variável", input: ["textlabel,textlabel_variable,ilabel"]});
								newform.push({label: "Valor", input: ["text,value,itext"]});

								newform.push({label: "Período", input: ["textlabel,textlabel_period,ilabel"]});
								if (data.period == "yearly"){
									newform.push({label: "Data", input: ["select,value_of_date,iselect"]});
								}else if(data.period == "monthly"){
									newform.push({label: "Data", input: ["select,value_of_date_year,iselect","select,value_of_date,iselect"]});
								}else if(data.period == "daily"){
									newform.push({label: "Data", input: ["text,value_of_date,itext"]});
								}
								newform.push({label: "Descrição", input: ["textlabel,textlabel_explanation,ilabel"]});

								var formbuild = $("#dashboard-content .content").append(buildForm(newform,txtOption));

								if (data.period == "yearly"){
									$.ajax({
										type: 'GET',
										dataType: 'json',
										url: '/api/period/year?api_key=$$key'.render({
												key: $.cookie("key")
											}),
										success: function(data, textStatus, jqXHR){
											$("#dashboard-content .content select#value_of_date option").remove();
											$.each(data.options, function(index,value){
												$("#dashboard-content .content select#value_of_date").append("<option value='$$value'>$$text</option>".render({
													text:data.options[index].text,
													value:data.options[index].value
													}));
											});
											$("#dashboard-content .content select#value_of_date option:last").attr("selected","selected");
										}
									});
								}else if(data.period == "monthly"){
									$("#dashboard-content .content select#value_of_date").hide();
									$.ajax({
										type: 'GET',
										dataType: 'json',
										url: '/api/period/year?api_key=$$key'.render({
												key: $.cookie("key")
											}),
										success: function(data, textStatus, jqXHR){
											$("#dashboard-content .content select#value_of_date_year option").remove();
											$("#dashboard-content .content select#value_of_date_year").append("<option value=''>Selecione o ano</option>");
											$.each(data.options, function(index,value){
												$("#dashboard-content .content select#value_of_date_year").append("<option value='$$value'>$$text</option>".render({
													text:data.options[index].text,
													value:data.options[index].value
													}));
											});
											$("#dashboard-content .content select#value_of_date option:last").attr("selected","selected");

											$("#dashboard-content .content select#value_of_date_year").change(function(){
												$("#dashboard-content .content select#value_of_date option").remove();
												$("#dashboard-content .content select#value_of_date").hide();
												if ($(this).find("option:selected").val() != ""){
													$("#dashboard-content .content select#value_of_date").show();
													$.ajax({
														type: 'GET',
														dataType: 'json',
														url: '/api/period/year/$$year/month?api_key=$$key'.render({
																key: $.cookie("key"),
																year: $("#dashboard-content .content select#value_of_date_year option:selected").html()
															}),
														success: function(data, textStatus, jqXHR){
															$.each(data.options, function(index,value){
																$("#dashboard-content .content select#value_of_date").append("<option value='$$value'>$$text</option>".render({
																	text:data.options[index].text,
																	value:data.options[index].value
																	}));
															});
														}
													});
												}
											});
										}
									});
								}else if(data.period == "daily"){
									$("#dashboard-content .content input#value_of_date").datepicker({
																									dateFormat: 'dd/mm/yy',
																									defaultDate: "0",
																									changeMonth: true,
																									changeYear: true
																									});
								}

								$("#dashboard-content .content .botao-form[ref='enviar']").html("Adicionar");
								$("#dashboard-content .content .botao-form[ref='cancelar']").html("Voltar");
								$(formbuild).find("div .field:odd").addClass("odd");
								$(formbuild).find(".form-buttons").width($(formbuild).find(".form").width());
								$("#dashboard-content .content div.historic table").width($("#dashboard-content .content").find(".form").width());

								$(formbuild).find("div#textlabel_variable").html(data.name);
								$(formbuild).find("div#textlabel_explanation").html(data.explanation);
								$(formbuild).find("div#textlabel_period").html(variable_periods[data.period]);


								$("#dashboard-content .content .botao-form[ref='enviar']").click(function(){

									if ($(this).html() == "Adicionar"){
										var ajax_type = "POST";
										var api_method = "create";
										var ajax_url = $.getUrlVar("url") + "/value";
									}else if ($(this).html() == "Editar"){
										var ajax_type = "POST";
										var api_method = "update";
										var ajax_url = $.getUrlVar("url") + "/value/" + $("table.history tbody tr.selected").attr("value-id");
									}

									resetWarnings();
									if ($(this).parent().parent().find("#value").val() == ""){
										$(".form-aviso").setWarning({msg: "Por favor informe o Valor"});
									}else{
										var data_formatada = "";
										if (data.period == "yearly" || data.period == "monthly"){
											data_formatada = $(this).parent().parent().find("#value_of_date option:selected").val();
										}else if (data.period == "daily"){
											data_formatada = $.convertDate($(this).parent().parent().find("#value_of_date").val()," ");
										}
										args = [{name: "api_key", value: $.cookie("key"),},
												{name: "variable.value." + api_method + ".value", value: $(this).parent().parent().find("#value").val()},
												{name: "variable.value." + api_method + ".value_of_date", value: data_formatada},
												{name: "variable.value." + api_method + ".variable_id", value: getIdFromUrl($.getUrlVar("url"))},
												];

										$("#dashboard-content .content .botao-form[ref='enviar']").hide();
										$.ajax({
											type: ajax_type,
											dataType: 'json',
											url: ajax_url,
											data: args,
											success: function(data, textStatus, jqXHR){
												resetWarnings();
												$("#aviso").setWarning({msg: "Cadastro editado com sucesso.".render({
															codigo: jqXHR.status
															})
												});
												$("#dashboard-content .content .botao-form[ref='enviar']").html("Adicionar");
												$("#dashboard-content .content .botao-form[ref='cancelar']").html("Voltar");
												$("#dashboard-content .content .form").find(".title").html("Adicionar Valor");
												$(formbuild).find("input#value").val("");
												$(formbuild).find("#value_of_date").val("");
												$("#dashboard-content .content .form").find("select").attr("disabled",false);
												$("table.history tbody tr").removeClass("selected");
												buildVariableHistory();
											},
											error: function(data){
												$(".form-aviso").setWarning({msg: "Erro ao editar. Já existe valor para esse Período".render({
															erro: $.parseJSON(data.responseText).error
															})
												});
												$("#dashboard-content .content .botao-form[ref='cancelar']").html("Voltar");
											},
											complete: function(data){
												$("#dashboard-content .content .botao-form[ref='enviar']").show();
											}
										});
									}
								});
								$("#dashboard-content .content .botao-form[ref='cancelar']").click(function(){
									resetWarnings();
									if ($(this).html() == "Voltar"){
										history.back();
									}else if ($(this).html() == "Cancelar"){
										$("#dashboard-content .content .form").find(".title").html("Adicionar Valor");
										$("#dashboard-content .content .botao-form[ref='enviar']").html("Adicionar");
										$("#dashboard-content .content .botao-form[ref='cancelar']").html("Voltar");
										$(formbuild).find("input#value").val("");
										$(formbuild).find("input#value_of_date").val("");
										$("#dashboard-content .content .form").find("select").attr("disabled",false);
										$("table.history tbody tr").removeClass("selected");
										$("#dashboard-content .content .botao-form[ref='enviar']").show();
									}
								});
							}

							$("#dashboard-content .content").append("<div class='historico'></div>");

							buildVariableHistory();
						},
						error: function(data){
							switch(data.status){
								case 400:
									$(".form-aviso").setWarning({msg: "Erro: ($$codigo)".render({
												codigo: $.parseJSON(data.responseText).error
												})
									});
									break;
							}
						}
					});
				}
			}else if (getUrlSub() == "indicator"){
				/*  INDICATOR  */
				if ($.getUrlVar("option") == "list" || $.getUrlVar("option") == undefined){

					var indicatorList = buildDataTable({
							headers: ["Nome","Formula","Data Criação","_"]
							});

					$("#dashboard-content .content").append(indicatorList);

					$("#button-add").click(function(){
						resetWarnings();
						location.hash = "#!/" + getUrlSub() + "?option=add";
					});

					$.ajax({
						type: 'GET',
						dataType: 'json',
						url: '/api/variable?api_key=$$key'.render({
								key: $.cookie("key"),
								userid: $.cookie("user.id")
								}),
						success: function(data, textStatus, jqXHR){
							var data_variables = [];
							$.each(data.variables, function(index,value){
								data_variables.push({"id":data.variables[index].id,"name":data.variables[index].name});
							});
							$("#results").dataTable( {
								  "oLanguage": {
												"sUrl": "js/dataTables.pt-br.txt"
												},
								  "bProcessing": true,
								  "sAjaxSource": '/api/indicator?api_key=$$key&content-type=application/json&columns=name,formula,created_at,url,_,_'.render({
										key: $.cookie("key")
										}),
								  "aoColumnDefs": [
													{ "bSearchable": false, "bSortable": false, "sClass": "botoes", "sWidth": "60px", "aTargets": [ 3 ] },
													{ "sClass": "center", "aTargets": [ 2 ] },
													{ "fnRender": function ( oObj, sVal ) {
																	return $.format.date(sVal,"dd/MM/yyyy HH:mm:ss");
																  }, "aTargets": [ 2 ]
													},
													{ "fnRender": function ( oObj, sVal ) {
																	return formataFormula(sVal,data_variables);
																  }, "aTargets": [ 1 ]
													},
												  ],
								   "fnDrawCallback": function(){
										DTdesenhaBotoes();
									}
							} );
						},
						error: function(data){
							$("#aviso").setWarning({msg: "Erro ao carregar ($$codigo)".render({
										codigo: $.parseJSON(data.responseText).error
									})
							});
						}
					});

				}else if ($.getUrlVar("option") == "add" || $.getUrlVar("option") == "edit"){

					var txtOption = ($.getUrlVar("option") == "add") ? "Cadastrar" : "Editar";

					var newform = [];

					newform.push({label: "Nome", input: ["text,name,itext"]});
					newform.push({label: "Formula<br /><a href='javascript: void(0);' id='help-formula'>ajuda</a>", input: ["textarea,formula,itext"]});
					newform.push({label: "Explicação", input: ["textarea,explanation,itext"]});
					newform.push({label: "Direção de classificação", input: ["select,sort_direction,iselect"]});
					newform.push({label: "Meta", input: ["select,goal_operator,iselect200px","text,goal,itext200px"]});
					newform.push({label: "Fonte (Meta)", input: ["text,goal_source,itext"]});
					newform.push({label: "Explicação (Meta)", input: ["textarea,goal_explanation,itext"]});
					newform.push({label: "Eixo", input: ["select,axis,iselect"]});
					newform.push({label: "Fonte", input: ["text,source,itext"]});
					newform.push({label: "Tags", input: ["text,tags,itext"]});

					var formbuild = $("#dashboard-content .content").append(buildForm(newform,txtOption));
					$(formbuild).find("div .field:odd").addClass("odd");
					$(formbuild).find(".form").width(780);
					$(formbuild).find(".form-buttons").width($(formbuild).find(".form").width());

					$(formbuild).find("#name").qtip( $.extend(true, {}, qtip_input, {
							content: "Nome do Indicador"
					}));
					$(formbuild).find("a#help-formula").qtip( $.extend(true, {}, qtip_editor, {
							content: "Crie a fórmula selecionando as variáveis ao lado e os botões de operações abaixo.<br />Para excluir um parâmetro adicionado, clique sobre o mesmo e depois aperte Delete no seu teclado."
					}));
					$("#formula-editor .button").qtip( $.extend(true, {}, qtip_editor, {
							content: "Adiciona a Variável/Valor na fórmula."
					}));
					$("input#formula-input").qtip( $.extend(true, {}, qtip_editor, {
							content: "Utilize esse campo para inserir valores manualmente."
					}));
					$(formbuild).find("#tags").qtip( $.extend(true, {}, qtip_input, {
							content: "Tags separadas por vírgula"
					}));

					$.ajax({
						type: 'GET',
						dataType: 'json',
						url: '/api/axis?api_key=$$key'.render({
								key: $.cookie("key")
								}),
						success: function(data, textStatus, jqXHR){
							var eixos = [];
							$.each(data.axis, function(index,value){
								eixos[String(data.axis[index].id)] = String(data.axis[index].name);
							});

							$.each(eixos,function(key, value){
								$("#dashboard-content .content select#axis").append($("<option></option>").val(key).html(value));
							});

						},
						error: function(data){
							$("#aviso").setWarning({msg: "Erro ao carregar ($$codigo)".render({
										codigo: $.parseJSON(data.responseText).error
									})
							});
						}
					});

					$.each(goal_operators,function(key, value){
						$("#dashboard-content .content select#goal_operator").append($("<option></option>").val(key).html(value));
					});

					$.each(sort_directions,function(key, value){
						$("#dashboard-content .content select#sort_direction").append($("<option></option>").val(key).html(value));
					});

					$("#dashboard-content .content textarea#formula").after("<div id='formula-editor'><div class='editor'><div class='editor-content'></div></div><div class='button'><<</div><div class='variables'></div><div class='user-input'></div><div class='operators'></div></div>");
					$("#formula-editor .user-input").append("<input type='text' id='formula-input' placeholder='valor'>");
					$("#formula-editor .operators").append("<div class='op-button' val='$$value' title='$$title'>$$caption</div>".render({value: "+",caption: "+",title: "Soma"}));
					$("#formula-editor .operators").append("<div class='op-button' val='$$value' title='$$title'>$$caption</div>".render({value: "-",caption: "-",title: "Subtração"}));
					$("#formula-editor .operators").append("<div class='op-button' val='$$value' title='$$title'>$$caption</div>".render({value: "/",caption: "÷",title: "Divisão"}));
					$("#formula-editor .operators").append("<div class='op-button' val='$$value' title='$$title'>$$caption</div>".render({value: "*",caption: "×",title: "Multiplicação"}));
					$("#formula-editor .operators").append("<div class='op-button' val='$$value' title='$$title''>$$caption</div>".render({value: "(",caption: "(",title: "Abre Parenteses"}));
					$("#formula-editor .operators").append("<div class='op-button' val='$$value' title='$$title'>$$caption</div>".render({value: ")",caption: ")",title: "Fecha Parenteses"}));
					$("#formula-editor .operators").append("<div class='op-button' val='$$value' title='$$title'>$$caption</div>".render({value: "√",caption: "√",title: "Raíz Quadrada"}));
					$("#formula-editor .operators").append("<div class='op-button' val='$$value' title='$$title'>$$caption</div>".render({value: "CONCATENAR",caption: "[ ]",title: "Concatenar"}));
					$("#formula-editor .operators").append("<div class='reset-button' val='erase' title='apagar tudo'>apagar tudo</div>");
					$("#dashboard-content .content textarea#formula").hide();

					$("html").click(function(e){
						click_editor = false;
					});
					$("html").keydown(function(e){
						if (click_editor){
							if (e.which == 46){ //TECLA DEL
								$("#formula-editor .editor-content .selected").remove();
							}else if (e.which == 8){ //TECLA BACKSPACE
								e.preventDefault();
								return false;
							}
						}
					});
					$("#formula-editor #formula-input").keydown(function(e){
						if (e.which == 13){ //TECLA ENTER
							e.stopPropagation();
							$("#formula-editor .button").click();
							return false;
						}
					});
					$("#formula-editor .editor").click(function(e){
						click_editor = true;
						e.stopPropagation();
						if ($(e.target).hasClass("f-operator") || $(e.target).hasClass("f-variable") || $(e.target).hasClass("f-input")){
							$(e.target).toggleClass("selected");
						}
					});

					$("#formula-editor .button").click(function(e){
						if ($(this).parent().find(".variables .selected").length > 0){
							var newItem = $(this).parent().find(".editor .editor-content").append("<div class='f-variable' var_id='$$var_id'>$$nome</div>".render({
																																			nome: $(this).parent().find(".variables .selected").html(),
																																			var_id: $(this).parent().find(".variables .selected").attr("var_id")
																																			}));
							var period_selected = $(this).parent().find(".variables .selected").attr("period");
							$(this).parent().find(".variables .item[period!='"+period_selected+"']").hide();
						}else if ($(this).parent().find("input#formula-input").val() != ""){
							var newItem = $(this).parent().find(".editor .editor-content").append("<div class='f-input'>$$valor</div>".render({
																																			valor: $(this).parent().find("input#formula-input").val()
																																			}));
							$("input#formula-input").val("");
						}
						updateFormula();
					});

					$("#formula-editor .op-button").click(function(){
						if (!$(this).hasClass("op-button-disabled")){
							var newItem = $("#formula-editor .editor .editor-content").append("<div class='f-operator' val='$$value'>$$caption</div>".render({
																																				value: $(this).attr("val"),
																																				caption: $(this).html()
																																				}));
							updateFormula();
							if ($(this).attr("val") == "CONCATENAR"){
								$("#formula-editor .op-button[value!='erase']").addClass("op-button-disabled");
							}
						}else{
						}
					});
					$("#formula-editor .reset-button").click(function(){
						$("#formula-editor .editor .editor-content").empty();
						$("#formula-editor .op-button").removeClass("op-button-disabled");
						$("#formula-editor .variables .item").show();
						updateFormula();
					});
					$("#formula-editor input#formula-input").focus(function(){
						$("#formula-editor .variables .item").removeClass("selected");
					});
					$.ajax({
						type: 'GET',
						dataType: 'json',
						url: '/api/variable?api_key=$$key'.render({
										key: $.cookie("key")
								}),
						success: function(data, textStatus, jqXHR){
							$.each(data.variables, function(index,value){
								$("#formula-editor .variables").append($("<div class='item'></div>").attr({"var_id":data.variables[index].id,"period":data.variables[index].period}).html(data.variables[index].name));
							});
							$("#formula-editor .variables .item").click(function(e){
								if ($(this).hasClass("selected")){
									$(this).removeClass("selected");
								}else{
									$(this).parent().find(".item").removeClass("selected");
									$(this).addClass("selected");
								}
								e.stopPropagation();
							});
							$("#formula-editor .variables .item").dblclick(function(e){
								if (!$(this).hasClass("selected")){
									$(this).parent().find(".item").removeClass("selected");
									$(this).addClass("selected");
								}
								$("#formula-editor .button").click();
								e.stopPropagation();
							});
							convertFormulaToCss();
						},
						error: function(data){
							$("#aviso").setWarning({msg: "Erro ao carregar ($$codigo)".render({
										codigo: $.parseJSON(data.responseText).error
									})
							});
						}
					});


					if ($.getUrlVar("option") == "add"){
						$("#dashboard-content .content .botao-form[ref='enviar']").click(function(){
							resetWarnings();
							if ($(this).parent().parent().find("#name").val() == ""){
								$(".form-aviso").setWarning({msg: "Por favor informe o Nome"});
							}else if ($(this).parent().parent().find("#formula").val() == ""){
								$(".form-aviso").setWarning({msg: "Por favor informe a Fórmula"});
							}else{
								args = [{name: "api_key", value: $.cookie("key"),},
										{name: "indicator.create.name", value: $(this).parent().parent().find("#name").val()},
										{name: "indicator.create.formula", value: $(this).parent().parent().find("#formula").val()},
										{name: "indicator.create.explanation", value: $(this).parent().parent().find("#explanation").val()},
										{name: "indicator.create.sort_diretion", value: $(this).parent().parent().find("#sort_direction option:selected").val()},
										{name: "indicator.create.goal", value: $(this).parent().parent().find("#goal").val()},
										{name: "indicator.create.goal_source", value: $(this).parent().parent().find("#goal_source").val()},
										{name: "indicator.create.goal_operator", value: $(this).parent().parent().find("#goal_operator option:selected").val()},
										{name: "indicator.create.goal_explanation", value: $(this).parent().parent().find("#goal_explanation").val()},
										{name: "indicator.create.axis_id", value: $(this).parent().parent().find("#axis option:selected").val()},
										{name: "indicator.create.source", value: $(this).parent().parent().find("#source").val()},
										{name: "indicator.create.tags", value: $(this).parent().parent().find("#tags").val()},
										];
								$("#dashboard-content .content .botao-form[ref='enviar']").hide();
								$.ajax({
									type: 'POST',
									dataType: 'json',
									url: '/api/indicator',
									data: args,
									success: function(data,status,jqXHR){
										$("#aviso").setWarning({msg: "Cadastro efetuado com sucesso.".render({
													codigo: jqXHR.status
													})
										});
										location.hash = "#!/"+getUrlSub();
									},
									error: function(data){
										switch(data.status){
											case 400:
												$("#aviso").setWarning({msg: "Erro ao cadastrar. ($$codigo)".render({
															codigo: $.parseJSON(data.responseText).error
															})
												});
												break;
										}
										$("#dashboard-content .content .botao-form[ref='enviar']").show();
									}
								});
							}
						});
					}else if ($.getUrlVar("option") == "edit"){
						$.ajax({
							type: 'GET',
							dataType: 'json',
							url: $.getUrlVar("url") + "?api_key=$$key".render({
										key: $.cookie("key")
								}),
							success: function(data,status,jqXHR){
								switch(jqXHR.status){
									case 200:
										$(formbuild).find("input#name").val(data.name);
										$(formbuild).find("textarea#formula").val(data.formula);
										$(formbuild).find("textarea#explanation").val(data.explanation);
										$(formbuild).find("select#sort_direction").val(data.sort_direction);
										$(formbuild).find("input#goal").val(data.goal);
										$(formbuild).find("input#goal_source").val(data.goal_source);
										$(formbuild).find("select#goal_operator").val(data.goal_operator);
										$(formbuild).find("textarea#goal_explanation").val(data.goal_explanation);
										$(formbuild).find("select#axis").val(data.axis_id);
										$(formbuild).find("input#source").val(data.source);
										$(formbuild).find("input#tags").val(data.tags);
										if ($("#formula-editor .variables .item").length > 0) convertFormulaToCss();
										break;
								}
							},
							error: function(data){
								switch(data.status){
									case 400:
										$(".form-aviso").setWarning({msg: "Erro: ($$codigo)".render({
													codigo: $.parseJSON(data.responseText).error
													})
										});
										break;
								}
							}
						});

						$("#dashboard-content .content .botao-form[ref='enviar']").click(function(){
							resetWarnings();
							if ($(this).parent().parent().find("#name").val() == ""){
								$(".form-aviso").setWarning({msg: "Por favor informe o Nome"});
							}else if ($(this).parent().parent().find("#formula").val() == ""){
								$(".form-aviso").setWarning({msg: "Por favor informe a Fórmula"});
							}else{
								args = [{name: "api_key", value: $.cookie("key"),},
										{name: "indicator.update.name", value: $(this).parent().parent().find("#name").val()},
										{name: "indicator.update.formula", value: $(this).parent().parent().find("#formula").val()},
										{name: "indicator.update.explanation", value: $(this).parent().parent().find("#explanation").val()},
										{name: "indicator.update.sort_direction", value: $(this).parent().parent().find("#sort_direction option:selected").val()},
										{name: "indicator.update.goal", value: $(this).parent().parent().find("#goal").val()},
										{name: "indicator.update.goal_source", value: $(this).parent().parent().find("#goal_source").val()},
										{name: "indicator.update.goal_operator", value: $(this).parent().parent().find("#goal_operator option:selected").val()},
										{name: "indicator.update.goal_explanation", value: $(this).parent().parent().find("#goal_explanation").val()},
										{name: "indicator.update.axis_id", value: $(this).parent().parent().find("#axis option:selected").val()},
										{name: "indicator.update.source", value: $(this).parent().parent().find("#source").val()},
										{name: "indicator.update.tags", value: $(this).parent().parent().find("#tags").val()},
										];

								$("#dashboard-content .content .botao-form[ref='enviar']").hide();
								$.ajax({
									type: 'POST',
									dataType: 'json',
									url: $.getUrlVar("url"),
									data: args,
									success: function(data, textStatus, jqXHR){
										$("#aviso").setWarning({msg: "Cadastro editado com sucesso.".render({
													codigo: jqXHR.status
													})
										});
										location.hash = "#!/"+getUrlSub();
										$("#dashboard-content .content .botao-form[ref='enviar']").show();
									},
									error: function(data){
										$(".form-aviso").setWarning({msg: "Erro ao editar. ($$erro)".render({
													erro: $.parseJSON(data.responseText).error
													})
										});
										$("#dashboard-content .content .botao-form[ref='enviar']").show();
									}
								});
							}
						});
					}
					$("#dashboard-content .content .botao-form[ref='cancelar']").click(function(){
						resetWarnings();
						history.back();
					});
				}else if ($.getUrlVar("option") == "delete"){

					deleteRegister({url:$.getUrlVar("url") + "?api_key=$$key".render({
													key: $.cookie("key")
											})});
				}
			}else if (getUrlSub() == "myindicator"){
				/*  INDICATORS */
				if ($.getUrlVar("option") == "list" || $.getUrlVar("option") == undefined){
					$.ajax({
						type: 'GET',
						dataType: 'json',
						url: '/api/indicator?api_key=$$key'.render({
								key: $.cookie("key"),
								userid: $.cookie("user.id")
								}),
						success: function(data, textStatus, jqXHR){
							var data_indicators = [];
							$.each(data.indicators, function(index,value){
								data_indicators.push({
														"id":data.indicators[index].id,
														"name":data.indicators[index].name,
														"formula":data.indicators[index].formula,
														"axis_id":data.indicators[index].axis_id,
														"axis":data.indicators[index].axis,
														"period":'yearly',
													 });
							});

							data_indicators.sort(function(a, b) {
							   return a.axis_id - b.axis_id;
							})

							$.ajax({
								type: 'GET',
								dataType: 'json',
								url: '/api/variable?api_key=$$key'.render({
										key: $.cookie("key"),
										userid: $.cookie("user.id")
										}),
								success: function(data, textStatus, jqXHR){
									var data_variables = [];
									$.each(data.variables, function(index,value){
										data_variables.push({"id":data.variables[index].id,"name":data.variables[index].name});
									});

									var axis_ant = "";
									var indicators_table = "";

									indicators_table = "<div class='indicadores_list'>";

									for (i = 0; i < data_indicators.length; i++){
										if (data_indicators[i].axis_id != axis_ant){
											if (i > 0){
												indicators_table += "</div>";
											}
											indicators_table += "<div class='eixos'><div class='title'>$$axis</div><div class='clear'></div>".render({axis: data_indicators[i].axis.name});
											axis_ant = data_indicators[i].axis_id;
										}
										var formula = formataFormula(data_indicators[i].formula,data_variables);
										indicators_table += "<div class='variable'><div class='name'>$$name</div><div class='formula'>$$formula</div><div class='link'><a href='javascript: void(0);' class='icone zoom' title='Série Histórica' alt='Série Histórica' indicator-id='$$id' period='$$period'>detalhes</a><a href='$$hash?option=edit&url=$$url' class='icone edit' title='adicionar valores' alt='adicionar valores'>editar</a></div><div class='clear'></div><div class='historico-popup'></div></div>".render({
											name: data_indicators[i].name,
											formula: formula,
											hash: "#!/"+getUrlSub(),
											url: "http://rnsp.aware.com.br/api/indicator/" + data_indicators[i].id,
											period: data_indicators[i].period,
											id: data_indicators[i].id
											});
										indicators_table += "<div class='clear'></div>";
									}

									indicators_table += "<div><div class='clear'>";

									$("#dashboard-content .content").append(indicators_table);

									$("#dashboard-content .content .indicadores_list .zoom").click( function(){
										var target = $(this).parent().parent();
										var indicator_period = $(this).attr("period");
										$.ajax({
											type: 'GET',
											dataType: 'json',
											url: '/api/indicator/$$id/variable/value?api_key=$$key'.render({
													key: $.cookie("key"),
													id: $(this).attr("indicator-id")
													}),
											success: function(data, textStatus, jqXHR){
												if (data.header){
													var history_table = "<table class='history'><thead><tr><th>Período</th>";
													$.each(data.header, function(index,value){
														history_table += "<th class='variavel'>$$variavel</th>".render({variavel:index});
													});
													history_table += "<th class='formula_valor'>Valor da Fórmula</th>";
													history_table += "</tr><tbody>";
													$.each(data.rows, function(index,value){
														history_table += "<tr><td class='periodo'>$$periodo</td>".render({periodo: $.convertDateToPeriod(data.rows[index].valid_from,indicator_period)});
														$.each(data.rows[index].valores, function(index2,value2){
															history_table += "<td class='valor' title='$$data'>$$valor</td>".render({
																	valor: data.rows[index].valores[index2].value,
																	data: $.convertDate(data.rows[index].valores[index2].value_of_date,"T")
															});
														});
														history_table += "<td class='formula_valor'>$$formula_valor</td>".render({formula_valor:data.rows[index].formula_value});
														history_table += "</tr></tbody>";
													});
													history_table += "</table>";
												}else{
													var history_table = "<table class='history'><thead><tr><th>nenhum registro encontrado</th></tr></thead></table>";
												}
												$(target).find(".historico-popup").html(history_table);
												$(target).find(".historico-popup").toggle();
											},
											error: function(data){

											}
										});
									});

									$("div.indicadores_list .eixos .title").click(function(){
										$(this).parent().find(".variable").toggle();
									});

								},
								error: function(data){
									$("#aviso").setWarning({msg: "Erro ao carregar ($$codigo)".render({
												codigo: $.parseJSON(data.responseText).error
											})
									});
								}
							});

						},
						error: function(data){
							$("#aviso").setWarning({msg: "Erro ao carregar ($$codigo)".render({
										codigo: $.parseJSON(data.responseText).error
									})
							});
						}
					});
				}else if ($.getUrlVar("option") == "edit"){ //EDIT MYINDICATOR

					$.ajax({
						type: 'GET',
						dataType: 'json',
						url: '/api/indicator/$$id?api_key=$$key'.render({
								key: $.cookie("key"),
								id: getIdFromUrl($.getUrlVar("url"))
								}),
						success: function(data, textStatus, jqXHR){

							$("#dashboard-content .content").append("<div class='filter_indicator'></div><div class='clear'><br /></div><div class='filter_result'></div><div class='historico'></div>");

							var data_indicator = data;

							//mostra historico
							buildIndicatorHistory({"id":getIdFromUrl($.getUrlVar("url")),
												   "period":data_indicator.period,
												   "target":$("#dashboard-content .content div.historico")
												   });


							var newform = [];
							newform.push({label: "Fórmula", input: ["textlabel,textlabel_formula,ilabel"]});
							newform.push({label: "Período", input: ["textlabel,textlabel_periodo,ilabel"]});
							if (data_indicator.period == "yearly"){
								newform.push({label: "Data", input: ["select,date_filter,iselect"]});
							}else if(data_indicator.period == "monthly"){
								newform.push({label: "Data", input: ["select,date_filter_year,iselect","select,date_filter,iselect"]});
							}else if(data_indicator.period == "daily"){
								newform.push({label: "Data", input: ["text,date_filter,itextdata"]});
							}else{
								newform.push({label: "Data", input: ["select,date_filter,iselect"]});
							}

							var formbuild = $("#dashboard-content .content .filter_indicator").append(buildForm(newform,"Pesquisar"));
							$(formbuild).find("div .field:odd").addClass("odd");
							$(formbuild).find(".form-buttons").width($(formbuild).find(".form").width());

							$.ajax({
								type: 'GET',
								dataType: 'json',
								url: '/api/variable?api_key=$$key'.render({
										key: $.cookie("key"),
										userid: $.cookie("user.id")
										}),
								success: function(data, textStatus, jqXHR){
									var data_variables = [];
									$.each(data.variables, function(index,value){
										data_variables.push({"id":data.variables[index].id,"name":data.variables[index].name});
									});
									$("#dashboard-content .content .filter_indicator #textlabel_formula").html(formataFormula(data_indicator.formula,data_variables));
								}
							});


							$("#dashboard-content .content .filter_indicator #textlabel_periodo").html(variable_periods[data_indicator.period]);

							$("#dashboard-content .content .filter_indicator .botao-form[ref='enviar']").html("Pesquisar");

							$("#dashboard-content .content .filter_indicator .botao-form[ref='cancelar']").html("Voltar");
							$("#dashboard-content .content .filter_indicator .botao-form[ref='cancelar']").click(function(){
								resetWarnings();
								location.hash = "#!/myindicator";
							});

							if (data_indicator.period == "yearly"){
								$.ajax({
									type: 'GET',
									dataType: 'json',
									url: '/api/period/year?api_key=$$key'.render({
											key: $.cookie("key")
										}),
									success: function(data, textStatus, jqXHR){
										$.each(data.options, function(index,value){
											$("#dashboard-content .content .filter_indicator select#date_filter").append("<option value='$$value'>$$text</option>".render({
												text:data.options[index].text,
												value:data.options[index].value
												}));
										});
									}
								});
							}else if(data_indicator.period == "monthly"){
								$.ajax({
									type: 'GET',
									dataType: 'json',
									url: '/api/period/year?api_key=$$key'.render({
											key: $.cookie("key")
										}),
									success: function(data, textStatus, jqXHR){
										$("#dashboard-content .content .filter_indicator select#date_filter").hide();
										$("#dashboard-content .content .filter_indicator select#date_filter_year option").remove();
										$("#dashboard-content .content .filter_indicator select#date_filter_year").append("<option value=''>Selecione o ano</option>");
										$.each(data.options, function(index,value){
											$("#dashboard-content .content .filter_indicator select#date_filter_year").append("<option value='$$value'>$$text</option>".render({
												text:data.options[index].text,
												value:data.options[index].value
												}));
										});
										$("#dashboard-content .content .filter_indicator select#date_filter option:last").attr("selected","selected");

										$("#dashboard-content .content .filter_indicator select#date_filter_year").change(function(){
											$("#dashboard-content .content .filter_result").empty();
											$("#dashboard-content .content .filter_indicator select#date_filter option").remove();
											$("#dashboard-content .content .filter_indicator select#date_filter").hide();
											if ($(this).find("option:selected").val() != ""){
												$("#dashboard-content .content .filter_indicator select#date_filter").show();
												$.ajax({
													type: 'GET',
													dataType: 'json',
													url: '/api/period/year/$$year/month?api_key=$$key'.render({
															key: $.cookie("key"),
															year: $("#dashboard-content .content .filter_indicator select#date_filter_year option:selected").html()
														}),
													success: function(data, textStatus, jqXHR){
														$.each(data.options, function(index,value){
															$("#dashboard-content .content .filter_indicator select#date_filter").append("<option value='$$value'>$$text</option>".render({
																text:data.options[index].text.split(" - ")[1],
																value:data.options[index].value
																}));
														});
													}
												});
											}
										});
									}
								});
							}else if(data_indicator.period == "daily"){
								$.each(data_variables, function(index,value){
									$("#dashboard-content .content .filter_indicator input#date_filter").datepicker({
																									dateFormat: 'dd/mm/yy',
																									defaultDate: "0",
																									changeYear: true,
																									changeMonth: true
																									});
								});
							}

							$("#dashboard-content .content .filter_indicator #date_filter").change( function(){
								 $("#dashboard-content .content .filter_result").empty();
							});

							$("#dashboard-content .content .filter_indicator .botao-form[ref='enviar']").click(function(){

								 $("#dashboard-content .content .filter_result").empty();

								$.ajax({
									type: 'GET',
									dataType: 'json',
									url: '/api/indicator/$$id/variable/period/$$period?api_key=$$key'.render({
											key: $.cookie("key"),
											id: getIdFromUrl($.getUrlVar("url")),
											period: $("#dashboard-content .content .filter_indicator select#date_filter option:selected").val()
											}),
									success: function(data, textStatus, jqXHR){
										var data_variables = data.rows;

										var newform = [];
										$.each(data_variables, function(index,value){
											newform.push({label: "<b>"+data_variables[index].name+"</b>", input: ["text,var_$$id,itext".render({id:data_variables[index].id})]});
											newform.push({label: "Descrição", input: ["textlabel,textlabel_explanation_$$id,ilabel".render({id:data_variables[index].id})]});
											newform.push({type: "div"});
										});

										newform.push({label: "", input: ["checkbox,no_data,icheckbox"]});
										newform.push({label: "Justificativa", input: ["text,justification_of_missing_field,itext"]});

										var formbuild = $("#dashboard-content .content .filter_result").append(buildForm(newform,data_indicator.name));
										$(formbuild).find("div .field:odd").addClass("odd");
										$(formbuild).find(".form-buttons").width($(formbuild).find(".form").width());

										$("#dashboard-content .content .filter_result input#no_data").after("Não possuo os dados.");
										$("#dashboard-content .content .filter_result .field:last").hide();
										$("#dashboard-content .content .filter_result input#no_data").click(function(){
											if ($(this).attr("checked")){
												$("#dashboard-content .content .filter_result .field:last").show();
											}else{
												$("#dashboard-content .content .filter_result .field:last").hide();
											}
										});

										$.each(data_variables, function(index,value){
											$("#dashboard-content .content .filter_result div#textlabel_explanation_$$id".render({id:data_variables[index].id})).html(data_variables[index].explanation)
											if (data_variables[index].value != null && data_variables[index].value != undefined && data_variables[index].value != ""){
												$("#dashboard-content .content .filter_result #var_$$id".render({id:data_variables[index].id})).val(data_variables[index].value);
												$("#dashboard-content .content .filter_result #var_$$id".render({id:data_variables[index].id})).attr("disabled","disabled");
												$("#dashboard-content .content .filter_result input#no_data").attr("disabled","disabled");
											}else{
												$("#dashboard-content .content .filter_result #var_$$id".render({id:data_variables[index].id})).attr("disabled",false);
												$("#dashboard-content .content .filter_result input#no_data").attr("disabled",false);
											}
										});

										$("#dashboard-content .content .filter_result .botao-form[ref='enviar']").click(function(){
											resetWarnings();

											$.each(data_variables, function(index,value){
												var data_formatada = "";
												if (data_indicator.period == "yearly" || data_indicator.period == "monthly"){
													data_formatada = $(this).parent().parent().find("#date_filter option:selected").val();
												}else if (data_indicator.period == "daily"){
													data_formatada = $(this).parent().parent().find("#date_filter").val();
												}
											});

											var informou_valores = true;
											$.each(data_variables, function(index,value){
												if ($("#dashboard-content .content .filter_result").find("#var_"+data_variables[index].id).val() == ""){
													informou_valores = false;
												}
											});

											if (!informou_valores && !$("#dashboard-content .content .filter_result input#no_data").attr("checked")){
												$(".filter_result .form-aviso").setWarning({msg: "Por favor informe os valores"});
											}else if ($("#dashboard-content .content .filter_result input#no_data").attr("checked") && $("#dashboard-content .content").find("#justification_of_missing_field").val() == ""){
												$(".filter_result .form-aviso").setWarning({msg: "Por favor informe a justificativa"});
											}else{
												$("#dashboard-content .content .filter_result .botao-form[ref='enviar']").hide();

												var cont_total = data_variables.length;
												var cont_sent = 0;
												var cont_returned = 0;

												var to_indicator = setInterval(function(){
													if (cont_sent < cont_total){
														console.log($("#dashboard-content .content .filter_result").find("#var_"+data_variables[cont_sent].id).attr("disabled"));
														if ($("#dashboard-content .content .filter_result").find("#var_"+data_variables[cont_sent].id).attr("disabled") == "disabled"){
															cont_sent++;
															cont_returned++;
														}else{
															var data_formatada = "";
															if (data_indicator.period == "yearly" || data_indicator.period == "monthly"){
																data_formatada = $("#dashboard-content .content .filter_indicator").find("#date_filter option:selected").val();
															}else if (data_indicator.period == "daily"){
																data_formatada = $("#dashboard-content .content .filter_indicator").find("#date_filter").val();
															}

															if (!$("#dashboard-content .content input#no_data").attr("checked")){
																args = [{name: "api_key", value: $.cookie("key"),},
																		{name: "variable.value.put.value", value: $("#dashboard-content .content .filter_result").find("#var_"+data_variables[cont_sent].id).val()},
																		{name: "variable.value.put.value_of_date", value: data_formatada}
																		];
															}else if ($("#dashboard-content .content .filter_result").find("#var_"+data_variables[cont_sent].id).val() == ""){
																args = [{name: "api_key", value: $.cookie("key"),},
																		{name: "variable.value.put.value", value: ""},
																		{name: "variable.value.put.value_of_date", value: ""},
																		{name: "variable.value.put.justification_of_missing_field", value: $("#dashboard-content .content .filter_result").find("#justification_of_missing_field").val()}
																		];
															}else{
																args = [{name: "api_key", value: $.cookie("key"),},
																		{name: "variable.value.put.value", value: $("#dashboard-content .content .filter_result").find("#var_"+data_variables[cont_sent].id).val()},
																		{name: "variable.value.put.value_of_date", value: data_formatada}
																		];
															}

															$.ajax({
																type: 'PUT',
																dataType: 'json',
																url: "/api/variable/$$var_id/value".render({var_id: data_variables[cont_sent].id}),
																data: args,
																success: function(data, textStatus, jqXHR){
																	cont_returned++;
																},
																error: function(data){
																	$(".filter_result .form-aviso").setWarning({msg: "Erro ao editar. ($$erro)".render({
																				erro: $.parseJSON(data.responseText).error
																				})
																	});
																	$("#dashboard-content .content .filter_result .botao-form[ref='enviar']").show();
																}
															});
															cont_sent++;
														}
													}
													if (cont_returned >= cont_total){
														$("#aviso").setWarning({msg: "Cadastro editado com sucesso.".render({
																	codigo: jqXHR.status
																	})
														});
														$("#dashboard-content .content .filter_result .botao-form[ref='enviar']").show();
														$("#dashboard-content .content .filter_result").empty();
														//mostra historico
														buildIndicatorHistory({"id":getIdFromUrl($.getUrlVar("url")),
																			   "period":data_indicator.period,
																			   "target":$("#dashboard-content .content div.historico")
																			   });
														clearInterval(to_indicator);
													}
												},500);

											}
										});
										$("#dashboard-content .content .botao-form[ref='cancelar']").click(function(){
											resetWarnings();
											$("#dashboard-content .content .filter_result").empty();
										});

									},
									error: function(data){
										$("#aviso").setWarning({msg: "Erro ao carregar ($$codigo)".render({
													codigo: $.parseJSON(data.responseText).error
												})
										});
									}
								});
							});
						}
					});
				}
			}else if (getUrlSub() == "prefs"){

				var newform = [];

				newform.push({label: "Nome", input: ["text,name,itext"]});
				newform.push({label: "Email", input: ["text,email,itext"]});
				newform.push({label: "Senha", input: ["password,password,itext"]});
				newform.push({label: "Confirmar Senha", input: ["password,password_confirm,itext"]});

				var formbuild = $("#dashboard-content .content").append(buildForm(newform,"Preferências"));
				$(formbuild).find("div .field:odd").addClass("odd");
				$(formbuild).find(".form-buttons").width($(formbuild).find(".form").width());

				$.ajax({
					type: 'GET',
					dataType: 'json',
					url: "/api/user/$$userid/?api_key=$$key".render({
								userid: $.cookie("user.id"),
								key: $.cookie("key")
						}),
					success: function(data,status,jqXHR){
						switch(jqXHR.status){
							case 200:
								$(formbuild).find("input#name").val(data.name);
								$(formbuild).find("input#email").val(data.email);
								break;
						}
					},
					error: function(data){
						switch(data.status){
							case 400:
								$(".form-aviso").setWarning({msg: "Erro: ($$codigo)".render({
											codigo: $.parseJSON(data.responseText).error
											})
								});
								break;
						}
					}
				});

				$("#dashboard-content .content .botao-form[ref='enviar']").html("Salvar");

				$("#dashboard-content .content .botao-form[ref='enviar']").click(function(){
					resetWarnings();
					if ($(this).parent().parent().find("#name").val() == ""){
						$(".form-aviso").setWarning({msg: "Por favor informe o Nome"});
					}else if ($(this).parent().parent().find("#email").val() == ""){
						$(".form-aviso").setWarning({msg: "Por favor informe o Email"});
					}else if ($(this).parent().parent().find("#password_confirm").val() != $(this).parent().parent().find("#password").val()){
						$(".form-aviso").setWarning({msg: "Confirmação de senha inválida"});
					}else{
						args = [{name: "api_key", value: $.cookie("key"),},
								{name: "user.update.name", value: $(this).parent().parent().find("#name").val()},
								{name: "user.update.email", value: $(this).parent().parent().find("#email").val(),}
								];

						if ($(this).parent().parent().find("#password").val() != ""){
							args.push({name: "user.update.password", value: $(this).parent().parent().find("#password").val(),},
								{name: "user.update.password_confirm", value: $(this).parent().parent().find("#password").val(),});
						}
						$("#dashboard-content .content .botao-form[ref='enviar']").hide();
						$.ajax({
							type: 'POST',
							dataType: 'json',
							url: "/api/user/$$userid/?api_key=$$key".render({
								userid: $.cookie("user.id"),
								key: $.cookie("key")
								}),
							data: args,
							success: function(data, textStatus, jqXHR){
								$("#aviso").setWarning({msg: "Preferências salvas.".render({
											codigo: jqXHR.status
											})
								});
								location.hash = "#!/"+getUrlSub();
								$("#dashboard-content .content .botao-form[ref='enviar']").show();
							},
							error: function(data){
								$(".form-aviso").setWarning({msg: "Erro ao editar. ($$erro)".render({
											erro: $.parseJSON(data.responseText).error
											})
								});
								$("#dashboard-content .content .botao-form[ref='enviar']").show();
							}
						});
					}
				});
				$("#dashboard-content .content .botao-form[ref='cancelar']").click(function(){
					resetWarnings();
					location.hash = "#!/dashboard";
				});
			}
		}else if (getUrlSub() == "logout"){
			if ($.cookie("key")){
				var url_logout = '/api/logout?api_key=$$key'.render({
									key: $.cookie("key")
							});
				$.cookie("user.id",null);
				$.cookie("key",null);
				$.ajax({
					type: 'GET',
					dataType: 'json',
					url: url_logout,
					success: function(data, textStatus, jqXHR){
						switch(jqXHR.status){
							case 200:
								resetWarnings();
								resetDashboard();
								location.hash = "";
								break;
						}
					}
				});
			}else{
				resetWarnings();
				resetDashboard();
				location.hash = "";
			}
		}else if(getUrlSub() == ""){
			if ($.cookie("key") == null || $.cookie("key") == ""){
				resetDashboard();
				$("#dashboard #form-login").show();
			}else{
				location.hash = "!/dashboard";
			}
		}
	}
	$(window).hashchange();

});
