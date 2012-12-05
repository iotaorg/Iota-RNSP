var indicadores_list;
var eixos_list = {"dados": []};
var users_list;
var indicadorID;
var indicadorDATA;
var dadosGrafico = {"dados": [], "labels": []};
var carregouTabela = false;

var accentMap = {
	"á": "a",
	"ã": "a",
	"à": "a",
	"é": "e",
	"ê": "e",
	"í": "i",
	"ó": "o",
	"õ": "o",
	"ú": "u",
	"ç": "c"
};
var normalize = function( term ) {
	var ret = "";
	for ( var i = 0; i < term.length; i++ ) {
		ret += accentMap[ term.charAt(i) ] || term.charAt(i);
	}
	return ret.toLowerCase();
};

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
	getUrlParams: function(){
		var params = window.location.href.split("?");
		if (params.length > 1){
			return "?" + params[1];
		}else{
			return "";
		}
	},
	removeItemInArray: function(obj,removeItem){
		obj = $.grep(obj, function(value) {
		  return value != removeItem;
		});		
		return obj;
	},
	setUrl: function(args){
		var url = "";
		if (args.view){
			url += "?view=" + args.view;
		}else if ($.getUrlVar("view")){
			url += "?view=" + $.getUrlVar("view");
		}
		if (args.graphs != undefined){
			if (args.graphs != ""){
				if (url == ""){
					url += "?graphs=" + args.graphs;
				}else{
					url += "&graphs=" + args.graphs;
				}
			}
		}else if ($.getUrlVar("graphs")){
			if (url == ""){
				url += "?graphs=" + $.getUrlVar("graphs");
			}else{
				url += "&graphs=" + $.getUrlVar("graphs");
			}
		}
		History.pushState(null, null, url);
	}
});

$(document).ready(function(){
	$.ajaxSetup({ cache: false });

	var graficos = [];
	
	function carregaIndicadoresCidades(){
		
		$.ajax({
			type: 'GET',
			dataType: 'json',
			url: api_path + '/api/public/user/$$role/'.render({role: role}),
			success: function(data, textStatus, jqXHR){
				users_list = [];
				indicadores_list = data.indicators;

				$(data.users).each(function(index,item){
					users_list.push({id: item.id, nome: item.city.name, pais: item.city.pais, uf: item.city.uf, uri: item.city.name_uri, label: item.city.name + " - " + item.city.uf});
				});
				
				$(indicadores_list).each(function(index,value){
					if (!findInJson(eixos_list.dados,"id",value.axis.id).found){
						eixos_list["dados"].push({id: value.axis.id, name: value.axis.name});	
					}
				});
				
				carregaIndicadores();
			},
			error: function(data){
				console.log("erro ao carregar informações dos indicadores");
			}
		});
	}

	function carregaIndicadores(){

		$("#axis_list").empty();
		
		$(eixos_list.dados).each(function(index,value){
			if (index == 0){
				$("#axis_list").append("<div class='select' axis-id='0'><div class='content-fill'>Categoria</div></div>");
				$("#axis_list").append("<div class='options'><div class='option' axis-id='0'>Categoria</div></div>");
			}
			$("#axis_list .options").append("<div class='option' axis-id='$$id'>$$nome</div>".render({
							id: value.id,
							nome: value.name
				}));
		});
		
		$("#axis_list .select").click(function(){
			$("#axis_list .options").toggle();
		});
		$("#axis_list .option").click(function(){
			$("#axis_list .select").attr("axis-id",$(this).attr("axis-id"));
			$("#axis_list .select .content-fill").html($(this).html());
			$("#axis_list .options").hide();
			if ($(this).attr("axis-id") != 0){
				$(".menu-left div.indicators .item").hide();
				$(".menu-left div.indicators .item[axis-id='$$axis_id']".render({axis_id: $(this).attr("axis-id")})).show();
			}else{
				$(".menu-left div.indicators .item").show();
			}
			$("#indicador-busca").val("");
			
		});
		$("#axis_list .options").hover(function(){
			if (typeof(t_categorias) != "undefined"){
				if (t_categorias){
					clearTimeout(t_categorias);	
				}
			}
		},function(){
			t_categorias = setTimeout(function(){
				$("#axis_list .options").hide();
			},2000)	;
		});

		$("#indicador-busca").keyup(function(){
			if ($(this).val() != ""){
				$(".indicators .item").hide();
				var termo = $(this).val();
				var matches = $('.indicators .item').filter(function() {
					var match = normalize(termo);
					
					var pattern = match;
					var re = new RegExp(pattern,'g');
				
					return re.test( normalize($(this).text()) );
				});
				if ($("#axis_list .select").attr("axis-id") != 0 && $("#axis_list .select").attr("axis-id") != ""){
					$(matches).each(function(index,element){
						if ($(this).attr("axis-id") == $("#axis_list .select").attr("axis-id")){
							$(this).fadeIn();
						}
					});
				}else{
					$(matches).fadeIn();
				}
			}else{
				refreshIndicadores();
			}
		});
		
		function refreshIndicadores(){
			$("#axis_list .options").hide();
			if ($("#axis_list .select").attr("axis-id") != 0){
				$(".menu-left div.indicators .item").hide();
				$(".menu-left div.indicators .item[axis-id='$$axis_id']".render({axis_id: $("#axis_list .select").attr("axis-id")})).show();
			}else{
				$(".menu-left div.indicators .item").show();
			}
			if ($("#indicador-busca").val() != ""){
				$(".indicators .item").hide();
				var termo = $("#indicador-busca").val();
				var matches = $('.indicators .item').filter(function() {
					var match = normalize(termo);
					
					var pattern = match;
					var re = new RegExp(pattern,'g');
				
					return re.test( normalize($(this).text()) );
				});
				if ($("#axis_list .select").attr("axis-id") != 0 && $("#axis_list .select").attr("axis-id") != ""){
					$(matches).find("[axis-id='$$axis_id']".render({axis_id: $("#axis_list .select").attr("axis-id")})).fadeIn();
				}else{
					$(matches).fadeIn();
				}
			}
		}
		
		$(".indicators").empty();
		$.each(indicadores_list, function(i,item){
			$(".indicators").append("<div class='item' indicator-id='$$id' axis-id='$$axis_id' name-uri='$$uri'>$$name</div>".render({
						id: item.id,
						name: item.name,
						axis_id: item.axis.id,
						uri: item.name_url
					}));
		});
		if (indicadorID == "" || indicadorID == undefined){
			indicadorID = $(".indicators .item:first").attr("indicator-id");
		}else{
			selectAxis(indicadorID);
		}
		$(".indicators .item[indicator-id='$$indicator_id']".render({indicator_id: indicadorID})).addClass("selected");
		$.each(indicadores_list, function(i,item){
			if (item.id == indicadorID){
				indicadorDATA = indicadores_list[i];
			}
		});
		$(".data-right .data-title .title").html($(".indicators .item[indicator-id='$$indicator_id']".render({indicator_id: indicadorID})).html());
		$(".data-right .data-title .description").html(indicadorDATA.explanation);
		$("#share-link").val(window.location.href);

		$(".indicators .item").click( function (){
			
			window.location.href = "/"+role+"/" + $(this).attr("name-uri") + $.getUrlParams();
			
			return;
			
			if (indicadorID == $(this).attr("indicator-id")){
				return;
			}
			indicadorID = $(this).attr("indicator-id");
			
			$(indicadores_list).each(function(index,item){
				if (item.id == indicadorID){
					indicadorDATA = item;	
				}
			});
			
			dadosGrafico = {"dados": [], "labels": []};
			$(".indicators .item").removeClass("selected");
			$(this).addClass("selected");
			$(".data-right .data-title .title").html($(".indicators .selected").html());
			$(".data-right .data-title .description").html(indicadorDATA.explanation);
			
			if ($(".data-content .tabs .selected").attr("id") == "tab-tabela"){
				carregouTabela = false;
				carregaTabela();
				$(".data-content .table").show();
			}else if ($(".data-content .tabs .selected").attr("id") == "tab-graficos"){
				carregouTabela = false;
				carregaTabela();
			}else{
			}
		});
		carregaTabela();

  	}

	function carregaTabela(){
		
		if (!carregouTabela){
			
			var indicador = indicadorID;
			var indicador_uri = $(".indicators div.selected").attr("name-uri");
	
			dadosGrafico = {"dados": [], "labels": []};
			
			var data_atual = new Date();
			var ano_anterior = data_atual.getFullYear() - 1;
			var date_labels = [];
			for (i = ano_anterior - 3; i <= ano_anterior; i++){
				dadosGrafico.labels.push(String(i));
			}

			var table_content = ""
			$(".data-content .table .content-fill").empty();
			table_content += "<table>";
			table_content += "<thead><tr><th>Cidade</th>";
			var data_atual = new Date();
			var ano_anterior = data_atual.getFullYear() - 1;
			for (i = ano_anterior - 3; i <= ano_anterior; i++){
				table_content += "<th>" + i + "</th>";
			}
			table_content += "<th>&nbsp;</th></tr></thead>";
			table_content += "<tbody>";
			table_content += "</tbody></table>";
			$(".data-content .table .content-fill").append(table_content);
	
			var total_users = users_list.length;
			var users_ready = 0;
			
			$(users_list).each(function(index,item){
				
				$.ajax({
					type: 'GET',
					dataType: 'json',
					url: api_path + '/api/public/user/$$userid/indicator/$$indicatorid/chart/period_axis'.render({
								userid: item.id,
								indicatorid: indicador
						}),
					success: function(data, textStatus, jqXHR){
						var valores = [];
	
						row_content = "<tr><td class='cidade'><a href='/$$role/$$pais_uri/$$uf/$$city_uri/$$indicador_uri'>$$cidade</a></td>".render({
									cidade: item.nome,
									uf: item.uf,
									pais_uri: item.pais,
									city_uri: item.uri,
									indicador_uri: indicador_uri,
									role: role
								});
						
						if (data.series.length < 4){
							for (j = 0; j < (4 - data.series.length); j++){
								row_content += "<td class='valor'>-</td>";
								valores.push(null);
							}
						}
						
						if (data.series.length > 4){
							var j_ini = data.series.length - 4;	
						}else{
							var j_ini = 0;	
						}
						
						for (j = j_ini; j < data.series.length; j++){
							row_content += "<td class='valor'>$$valor</td>".render({valor: $.formatNumber(data.series[j].sum, {format:"#,##0.###", locale:"br"})});
							valores.push(data.series[j].sum.toFixed(3));
						}
						row_content += "<td class='grafico'><a href='#' user-id='$$data_id'><canvas id='graph-$$id' width='40' height='20'></canvas></a></td>".render({
										id: index,
										data_id: item.id
									});
						graficos[index] = valores;
						dadosGrafico.dados.push({id: item.id, nome: item.nome, valores: valores, data: data, show: false});
						$(".data-content .table .content-fill tbody").append(row_content);
						
						$("td.grafico a").click(function(e){
							if($.getUrlVar("graphs")){
								var graphs = $.getUrlVar("graphs").split("-");
							}else{
								var graphs = [];
							}
							
							if (!findInArray(graphs,$(this).attr("user-id"))){
								graphs.push($(this).attr("user-id"));
							}
							
							e.preventDefault();
							$.setUrl({graphs: graphs.join("-"), view: "graph"});

						});
						
						users_ready++;
						
						if (users_ready >= total_users){
							geraGraficos();
							setaGraficos();
						}
						carregouTabela = true;
						
						setaTabs();
						
					},
					error: function(data){
						console.log("erro ao carregar informações do indicador");
					}
				});
				
			});
		}
  	}
	
	$.carregaGrafico = function(canvasId){

		var colors = ['#124646','#238080','#3cd3d3','#00a5d4','#015b75','#013342'];
		var color_meta = '#ff0000';

		RGraph.Clear(document.getElementById(canvasId));
		
		var legendas = [];
		
		var linhas = [];
		
		if (indicadorDATA.goal){
			linhas.push([ indicadorDATA.goal, indicadorDATA.goal, indicadorDATA.goal, indicadorDATA.goal ]);
			legendas.push({name: "Meta", color: color_meta, meta: true});
			var colors = ['#ff0000','#124646','#238080','#3cd3d3','#00a5d4','#015b75','#013342'];

			var ymax = indicadorDATA.goal;
			var ymin = indicadorDATA.goal;
			var maxlength = indicadorDATA.goal.length;
		}else{
			var ymin = 0;
			var ymax = 0;
			var maxlength = 1;
		}

		$.each(dadosGrafico.dados, function(i,item){
			if (item.show){
				linhas.push(item.valores);
				$.each(item.valores, function(index, valor){
					if (valor != null){
						if (ymin == 0) ymin = parseFloat(valor);
						if (parseFloat(valor) < ymin) ymin = parseFloat(valor);

						if (ymax == 0) ymax = parseFloat(valor);
						if (parseFloat(valor) > ymax) max = parseFloat(valor);

						if (String(valor).length > maxlength) maxlength = String(valor).length;
					}
				});
				if (indicadorDATA.goal){
					legendas.push({name: item.nome, color: colors[i+1], id: item.id});
				}else{
					legendas.push({name: item.nome, color: colors[i], id: item.id});
				}
			}
		});

		if (maxlength < 10) maxlength = 10;

		if ((ymin >= 0) && ((parseInt(ymin)-1) < 0)){
			ymin = 0;
		}else{
			ymin = parseInt(ymin) - 1;
		}

		ymin = 0;
		
		var line = new RGraph.Line(canvasId, linhas);
		line.Set('chart.labels', dadosGrafico.labels);
		line.Set('chart.ymin', ymin);
		line.Set('chart.gutter.left', maxlength*5);
		line.Set('chart.text.font', 'tahoma');
		line.Set('chart.text.color', '#bbbbbb');
		line.Set('chart.axis.color', '#bbbbbb');
		line.Set('chart.colors', colors);
		line.Set('chart.tickmarks', 'circle');
		line.Draw();
		
		montaLegenda({source: legendas, removable: true});
		
		if (ref == "comparacao"){
			setaTabs();
		}

	}
	
	function setGraphLine(id,status){
		$.each(dadosGrafico.dados, function(index,item){
			if (item.id == id){
				dadosGrafico.dados[index].show = status;
			}
		});
	}
	
	function clearGraphLines(){
		$.each(dadosGrafico.dados, function(index,item){
			dadosGrafico.dados[index].show = false;
		});
	}

	function montaLegenda(args){
		var legendas = args.source;
		$(".graph .legend").empty();
		
		var legenda = "";
		for (i = 0; i < legendas.length; i++){
			if (legendas[i].meta){
				var sClass = "item meta";
			}else{
				var sClass = "item";
			}
			legenda += "<div class='$$class'><div class='quad' style='background-color: $$color'></div><div class='label' style='color: $$color'>$$label</div><div class='close'><div class='icon' item-id='$$id' title='Remover' alt='Remover'>x</div></div></div>".render({
					label:legendas[i].name,
					color: legendas[i].color,
					class: sClass,
					id: legendas[i].id
					});
		}
		$(".graph .legend").append(legenda);
		
		if (args.removable){
			
			$(".data-content .graph .legend .item").hover(function(){
				if (!$(this).hasClass("meta")){
					$(this).find(".icon").fadeIn();
				}
			},function(){
				if (!$(this).hasClass("meta")){
					$(this).find(".icon").hide();
				}
			});
	
			$(".data-content .graph .legend .icon").click(function(){
				if ($(this).attr("item-id")){
					if($.getUrlVar("graphs")){
						var graphs = $.getUrlVar("graphs").split("-");
					}else{
						var graphs = [];
					}
					
					graphs = $.removeItemInArray(graphs,$(this).attr("item-id"));
					
					$.setUrl({graphs: graphs.join("-")});
	
				}
			});
		}
		
	}
	
	function geraGraficos(){
		for (i = 0; i < graficos.length; i++){

			var ymin = 0;

			$.each(graficos[i], function(index, valor){
				if (valor != null){
					if (ymin == 0) ymin = valor;
					if (valor < ymin) ymin = valor;
				}
			});

			var line = new RGraph.Line('graph-'+i, graficos[i]);
 			line.Set('chart.ylabels', false);
 			line.Set('chart.noaxes', true);
 			line.Set('chart.background.grid', false);
 			line.Set('chart.hmargin', 0);
			line.Set('chart.ymin', parseInt(ymin-1));
 			line.Set('chart.gutter.left', 0);
 			line.Set('chart.gutter.right', 0);
 			line.Set('chart.gutter.top', 0);
 			line.Set('chart.gutter.bottom', 0);
 			line.Set('chart.colors', ['#b4b4b4']);
            line.Draw();
		}
	}
	
	function setaTabs(){
		$(".data-content .tabs .item").removeClass("selected");
		if ($.getUrlVar("view") == "table" || !($.getUrlVar("view"))){
			$(".data-content .tabs #tab-tabela").addClass("selected");
			$(".data-content .graph").hide();
			$(".data-content .map").hide();
			$(".data-content .table").show();
		}else if ($.getUrlVar("view") == "graph"){
			$(".data-content .tabs #tab-graficos").addClass("selected");
			$(".data-content .table").hide();
			$(".data-content .map").hide();
			$(".data-content .graph").show();
		}else if ($.getUrlVar("view") == "map"){
			$(".data-content .tabs #tab-mapa").addClass("selected");
			$(".data-content .table").hide();
			$(".data-content .graph").hide();
			$(".data-content .map").show();
		}		
	}
	
	function setaGraficos(){
		if ($.getUrlVar("graphs")){
			clearGraphLines();
			var graphs = $.getUrlVar("graphs").split("-");
			$.each(graphs,function(index,value){
				setGraphLine(value,true);
			});
		}else{
			clearGraphLines();
		}
		$.carregaGrafico("main-graph");
	}

	$(".data-content .tabs .item").click( function (){
		$(".data-content .tabs .item").removeClass("selected");
		$(this).addClass("selected");
		if ($(this).attr("id") == "tab-tabela"){
			$.setUrl({view: "table"});
		}else if ($(this).attr("id") == "tab-graficos"){
			$.setUrl({view: "graph"});
		}else{
			$.setUrl({view: "map"});
		}
	});

	$("#button-share").click(function(){
		$(".share-link").toggle();
		$(this).toggleClass("down");
		$("#share-link").select();
	});
	$("#share-link").focus(function(){
		$(this).select();
	});
	$("#share-link").click(function(){
		$(this).select();
	});
	$("#share-link").keypress(function(e){
		e.preventDefault();
	});

	$("#graph-search-user").autocomplete({
		source: function( request, response ) {
			var matcher = new RegExp( $.ui.autocomplete.escapeRegex( request.term ), "i" );
			response( $.grep( users_list, function( value ) {
				value = value.label || value.value || value;
				return matcher.test( value ) || matcher.test( normalize( value ) );
			}) );
		},
		focus: function(event, ui){
			$("#button-search-user").attr("disabled",true);
		},
		select: function(event, ui){
			$("#graph-user-selected").val(ui.item.id);
			$("#button-search-user").attr("disabled",false);
		},
	});

	$("#button-search-user").click(function(){

		if($.getUrlVar("graphs")){
			var graphs = $.getUrlVar("graphs").split("-");
		}else{
			var graphs = [];
		}
		
		if (!findInArray(graphs,$("#graph-user-selected").val())){
			graphs.push($("#graph-user-selected").val());
		}
		
		$.setUrl({graphs: graphs.join("-")});
		$("#graph-search-user").val("");
	});

	function selectAxis(id){

		var indicador = $(".indicators .item[indicator-id='$$id']".render({id: id}));
		var eixo = $("#axis_list .option[axis-id='$$id']".render({id: $(indicador).attr("axis-id")}));
		$("#axis_list .select").attr("axis-id",$(eixo).attr("axis-id"));
		$("#axis_list .select .content-fill").html($(eixo).html());
		$("#axis_list .options").hide();
		if ($(eixo).attr("axis-id") != 0){
			$(".menu-left div.indicators .item").hide();
			$(".menu-left div.indicators .item[axis-id='$$axis_id']".render({axis_id: $(eixo).attr("axis-id")})).show();
		}else{
			$(".menu-left div.indicators .item").show();
		}

	}

	if (ref == "comparacao"){
		carregaIndicadoresCidades();
	}

	var History = window.History; // Note: We are using a capital H instead of a lower h
    // Bind to StateChange Event
    History.Adapter.bind(window,'statechange',function(){ // Note: We are using statechange instead of popstate
        var State = History.getState(); // Note: We are using History.getState() instead of event.state
		setaTabs();
		setaGraficos();
		$("#share-link").val(window.location.href);
    });

});
