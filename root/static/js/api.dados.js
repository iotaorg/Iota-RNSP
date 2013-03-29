var indicadores_list;
var eixos_list = {"dados": []};
var users_list;
var indicadorID;
var indicadorDATA;
var dadosGrafico = {"dados": [], "labels": []};
var dadosMapa = [];
var markerCluster;
var carregouTabela = false;
var carregaVariacoes = true;

$(document).ready(function(){

	zoom_padrao = 4;
	$.ajaxSetup({ cache: false });

	var graficos = [];

	function carregaIndicadoresCidades(){

		$.ajax({
			type: 'GET',
			dataType: 'json',
			url: api_path + '/api/public/network'.render(),
			success: function(data, textStatus, jqXHR){
				users_list = [];
				indicadores_list = data.indicators;

				$(data.users).each(function(index,item){
					if (item.id == userID) cidade_uri = "/" + item.city.pais + "/" + item.city.uf + "/" + item.city.name_uri;
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

		eixos_list.dados.sort(function (a, b) {
			a = a.name,
			b = b.name;

			return a.localeCompare(b);
		});

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
		indicadores_list.sort(function (a, b) {
			a = a.name,
			b = b.name;

			return a.localeCompare(b);
		});
		$.each(indicadores_list, function(i,item){
			$(".indicators").append("<div class='item' indicator-id='$$id' axis-id='$$axis_id' name-uri='$$uri'>$$name</div>".render({
						id: item.id,
						name: item.name,
						axis_id: item.axis.id,
						uri: item.name_url
					}));
		});
		if (indicadorID == "" || indicadorID == undefined){
			if (ref != "home"){
				indicadorID = $(".indicators .item:first").attr("indicator-id");
			}
		}else{
			selectAxis(indicadorID);
		}
		$(".indicators .item[indicator-id='$$indicator_id']".render({indicator_id: indicadorID})).addClass("selected");
		$.each(indicadores_list, function(i,item){
			if (item.id == indicadorID){
				indicadorDATA = indicadores_list[i];
			}
		});
		if (indicadorID){
			$(".data-right .data-title .title").html($(".indicators .item[indicator-id='$$indicator_id']".render({indicator_id: indicadorID})).html());
			$(".data-right .data-title .description").html(indicadorDATA.explanation);
		}
		$(".indicators .item").click( function (){

			if (ref == "home"){
				window.location.href = "/" + $(this).attr("name-uri") + $.getUrlParams();
				return;
			}

			if (indicadorID == $(this).attr("indicator-id")){
				return;
			}
			indicadorID = $(this).attr("indicator-id");

			$(indicadores_list).each(function(index,item){
				if (item.id == indicadorID){
					indicadorDATA = item;
				}
			});

			$(".indicators .item").removeClass("selected");
			$(this).addClass("selected");
			$(".data-right .data-title .title").html($(".indicators .selected").html());
			$(".data-right .data-title .description").html(indicadorDATA.explanation);

			carregaVariacoes = true;

			if (ref == "comparacao"){
				var url = "/" + $(this).attr("name-uri") + $.getUrlParams();
				History.pushState(null, null, url);

				dadosGrafico = {"dados": [], "labels": []};

				if ($(".data-content .tabs .selected").attr("id") == "tab-tabela"){
					carregouTabela = false;
					carregaDadosTabela();
					$(".data-content .table").show();
				}else if ($(".data-content .tabs .selected").attr("id") == "tab-graficos"){
					carregouTabela = false;
					carregaDadosTabela();
				}else if ($(".data-content .tabs .selected").attr("id") == "tab-mapa"){
					carregouTabela = false;
					carregaDadosTabela();
				}
			}else if (ref == "indicador"){
				var url = "/"+cidade_uri + "/" + $(this).attr("name-uri") + $.getUrlParams();
				History.pushState(null, null, url);
				$.loadCidadeDataIndicador();
			}
		});
		if (ref == "comparacao"){
			carregaDadosTabela();
		}
  	}

	function carregaDadosTabela(){

		if (!carregouTabela){
			$.xhrPool.abortAll();

			var indicador = indicadorID;
			var indicador_uri = $(".indicators div.selected").attr("name-uri");

			dadosGrafico = {"dados": [], "labels": []};

			var data_atual = new Date();
			var ano_anterior = data_atual.getFullYear() - 1;
			var date_labels = [];
			for (i = ano_anterior - 3; i <= ano_anterior; i++){
				dadosGrafico.labels.push(String(i));
			}

			if (indicadorDATA.indicator_type == "varied"){
				if (carregaVariacoes){
					montaFiltroVariacao();
				}
			}else{
				removeFiltroVariacao();
			}

			montaDateRuler();

			var table_content = ""
			$(".data-content .table .content-fill").empty();
			table_content += "<table id='table-data'>";
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

						if (indicadorDATA.indicator_type == "varied"){
							if ($("#variationFilter option").length <= 0){
								if(data.series.length > 0){
									$.each(data.series[0].variations, function(index,item){
										$("#variationFilter").append("<option value='$$index'>$$name".render({
												index: index,
												name: item.name
											}));
									});
									$("#variationFilter").change(function(){
										carregouTabela = false;
										carregaVariacoes = false;
										carregaDadosTabela();
									});
								}
							}
						}

						var valores = [];

						row_content = "<tr user-id='$$id'><td class='cidade'><a href='/$$pais_uri/$$uf/$$city_uri/$$indicador_uri'>$$cidade</a></td>".render({
									id: item.id,
									cidade: item.nome,
									uf: item.uf,
									pais_uri: item.pais,
									city_uri: item.uri,
									indicador_uri: indicador_uri
								});
						var series = [];
						for (j = 0; j < data.series.length; j++){
							if (indicadorDATA.indicator_type == "varied"){
								series[data.series[j].label] = data.series[j].variations[$("#variationFilter").val()].value;
							}else{
								series[data.series[j].label] = data.series[j].sum;
							}
						}

						var data_atual = new Date();
						var ano_anterior = data_atual.getFullYear() - 1;
						var date_labels = [];

						for (i = ano_anterior - 3; i <= ano_anterior; i++){
							if (series[i] == "-" || series[i] == undefined){
								row_content += "<td class='valor'>-</td>";
								valores.push(null);
							}else{
								row_content += "<td class='valor'>$$valor</td>".render({
												valor: $.formatNumber(series[i], {format:"#,##0.##", locale:"br"})
											});
								valores.push(parseFloat(series[i]).toFixed(2));
							}

						}

						row_content += "<td class='grafico'><a href='#' user-id='$$data_id'><canvas id='graph-$$id' width='40' height='20'></canvas></a></td>".render({
										id: index,
										data_id: item.id
									});

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

						//alimenta dados dos graficos
						graficos[index] = valores;
						dadosGrafico.dados.push({
                            id: item.id,
                            nome: item.nome,
                            valores: valores,
                            data: data,
                            show: false,
                            latitude: data.city.latitude,
                            longitude: data.city.longitude
                        });

						//alimenta dados do mapa

						users_ready++;

						if (users_ready >= total_users){
							geraGraficos();
							setaGraficos();

							geraMapa();
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

	function montaFiltroVariacao(){
		$(".data-content .variationFilter").remove();
		$(".data-content .tabs").before("<div class='variationFilter'>Selecione uma Faixa: <select id='variationFilter'></select></div>");
	}

	function removeFiltroVariacao(){
		$(".data-content .variationFilter").remove();
	}

	function montaDateRuler(){

		var data_atual = new Date();
		var ano_anterior = data_atual.getFullYear() - 1;

		var grupos = 4;
		var ano_i = ano_anterior - (grupos * 4) + 1;

		$(".table .period").empty();
		$(".table .period").append("<div id='date-ruler'></div><div id='date-arrow'></div>");
		var cont = 0;
		var periodo = '';
		for (i = ano_i; i <= ano_anterior; i++){
			if (cont == 0){
				periodo += "<div class='item'>" + i;
			}else if (cont == 3){
				periodo += "-" + i + "</div>";
				cont = -1;
			}
			cont++;
		}
		$("#date-ruler").append(periodo);
		$("#date-ruler .item:last").addClass("active");
		setDateArrow();

		$("#date-ruler .item").click(function(){
			$("#date-ruler").find(".item").removeClass("active");
			$(this).addClass("active");
			setDateArrow();
		});
	}

	function setDateArrow(){
		var item_pos = $("#date-ruler .item.active").offset();

		var diff = ($("#date-ruler .item.active").innerWidth() - $("#date-arrow").outerWidth()) / 2;

		var new_pos = {top: item_pos.top+15, left: item_pos.left+diff};

		$("#date-arrow").fadeOut("slow",function(){
			$(this).show();
			$(this).css("visibility","hidden");
			$(this).offset({
					top: new_pos.top,
					left: new_pos.left
				});

			$(this).css("visibility","");
			$(this).fadeIn(350);

		});
	}


	$.carregaGrafico = function(canvasId){

		RGraph.ObjectRegistry.Clear();
		var color_meta = '#ff0000';
		var colors = ['#124646','#238080','#3cd3d3','#00a5d4','#015b75','#013342'];
//		RGraph.Clear(document.getElementById(canvasId));

		var legendas = [];

		var linhas = [];

		var tooltips = [];

		if (indicadorDATA.goal){
			linhas.push([ indicadorDATA.goal, indicadorDATA.goal, indicadorDATA.goal, indicadorDATA.goal ]);
			tooltips.push(indicadorDATA.goal);
			tooltips.push(indicadorDATA.goal);
			tooltips.push(indicadorDATA.goal);
			tooltips.push(indicadorDATA.goal);
			legendas.push({name: "Referência de Meta", color: color_meta, meta: true});

			var ymax = indicadorDATA.goal;
			var ymin = indicadorDATA.goal;
			var maxlength = indicadorDATA.goal.length;
		}else{
			var ymin = 0;
			var ymax = 0;
			var maxlength = 1;
		}

		var color_index = 0;
		$.each(dadosGrafico.dados, function(i,item){
			if (item.show){
				linhas.push(item.valores);
				legendas.push({name: item.nome, color: colors[color_index], id: item.id});
				$.each(item.valores, function(index, valor){
					if (valor != null){
						if (ymin == 0) ymin = parseFloat(valor);
						if (parseFloat(valor) < ymin) ymin = parseFloat(valor);

						if (ymax == 0) ymax = parseFloat(valor);
						if (parseFloat(valor) > ymax) max = parseFloat(valor);

						if (String(valor).length > maxlength) maxlength = String(valor).length;

						tooltips.push(parseFloat(valor).toFixed(2));
					}else{
						tooltips.push(" "); //jogar valor em branco na tooltip caso a sequencia nao tenha valor
					}
				});
				color_index++;
			}
		});

		if (maxlength < 10) maxlength = 10;

		if ((ymin >= 0) && ((parseInt(ymin)-1) < 0)){
			ymin = 0;
		}else{
			ymin = parseInt(ymin) - 1;
		}

		ymin = 0;

		if (indicadorDATA.goal){
			colors.unshift(color_meta);
		}

		var line = new RGraph.Line(canvasId, linhas);
		RGraph.Clear(line.canvas);
		line.Set('chart.tooltips', tooltips);
		line.Set('chart.labels', dadosGrafico.labels);
		line.Set('chart.ymin', ymin);
		line.Set('chart.gutter.left', maxlength*5);
		line.Set('chart.text.font', 'tahoma');
		line.Set('chart.text.color', '#bbbbbb');
		line.Set('chart.axis.color', '#bbbbbb');
		line.Set('chart.colors', colors);
		line.Set('chart.tickmarks', 'filledcircle');
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
			if (typeof(map) != "undefined"){
				google.maps.event.trigger(map, 'resize');
				map.setZoom( map.getZoom() );
				if ($("#mapa").attr("lat")){
					var mapDefaultLocation = new google.maps.LatLng($("#mapa").attr("lat"), $("#mapa").attr("lng"));
					map.setCenter(mapDefaultLocation);
					$("#mapa").attr("lat","");
					$("#mapa").attr("lng","");
				}
			}
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

	function geraMapa(){


		var mapDefaultLocation = new google.maps.LatLng(-15.6778, -47.4384);
		var mapOptions = {
				center: mapDefaultLocation,
				zoom: zoom_padrao,
				mapTypeId: google.maps.MapTypeId.ROADMAP
			};

        map = new google.maps.Map(document.getElementById('mapa'), mapOptions);

		if (!$("#mapa").is(":visible")){
			$("#mapa").attr("lat",-15.6778);
			$("#mapa").attr("lng",-47.4384);
		}

		$("#mapa-filtro").empty();
		$("#mapa-filtro").append("<label>Selecione um Período:</label> <select id='mapa-filtro-periodo'></select>");
		$.each(dadosGrafico.labels,function(index,value){
			if (!value) return;
			$("#mapa-filtro select").append("<option value='$$index'>$$periodo</option>".render({
					index: index,
					periodo: value
				}));
		});

		$("#mapa-filtro select option:last").attr("selected",true);
		marcaMapa($("#mapa-filtro select option:selected").val());

		$("#mapa-filtro select").change(function(){
			marcaMapa($(this).find("option:selected").val());
		});

	}

	function marcaMapa(label_index){

		if (markerCluster) markerCluster.clearMarkers();

        var markers = [];


		var oldMin = "";
		var oldMax = "";
		var newMin = 10;

		dadosMapa = [];

		$.each(dadosGrafico.dados, function(index,item){
			if (item.valores[label_index] != null){

				var valor = parseInt(item.valores[label_index].replace(".",""));

				if (oldMin == "") oldMin = valor;
				if (oldMax == "") oldMax = valor;

				if (valor < oldMin) oldMin = valor;
				if (valor > oldMax) oldMax = valor;

				dadosMapa.push({id: item.id, nome: item.nome, valor: item.valores[label_index], latitude: item.latitude, longitude: item.longitude, novo_valor: valor});

			}
		});

		var newMax = 1000;

		$.each(dadosMapa, function(index,item){
			var novo_valor = parseInt(convertRangeValue(oldMin,oldMax,newMin,newMax,dadosMapa[index].novo_valor));
			if (isNaN(novo_valor)){
				dadosMapa[index].novo_valor = 1;
			}else{
				dadosMapa[index].novo_valor = novo_valor;
			}
		});


		$.each(dadosMapa, function(index,item){
			for (var i = 0; i < item.novo_valor; i++) {
				if (item.longitude){
					var latLng = new google.maps.LatLng(item.latitude,
						item.longitude);
					var marker = new google.maps.Marker({
						position: latLng,
						map: map
					});

					marker.__userID = item.id;
					marker.__position = latLng;
					marker.__valor = item.valor;
					marker.__nome = item.nome;

					markers.push(marker);


				}
			}
		});

		markerCluster = new MarkerClusterer(map, markers, {gridSize: 40});
		var numStyles = markerCluster.getStyles().length;

		markerCluster.setCalculator(customClusterText);
	}

	function customClusterText(markers,numStyles){

		var text;
		var title;

		var index = 0;
		var count = markers.length;
		var dv = count;
		while (dv !== 0){
			dv = parseInt(dv / 10, 10);
			index++;
		}

		index = Math.min(index, numStyles);

		if (markers.length > 0){
			text = $.formatNumber(markers[0].__valor, {format:"#,##0.##", locale:"br"});
			title = markers[0].__nome + " - " + text;
		}else{
			text = count;
		}

		return{
			text: text,
			index: index,
			title: title
		};

  	}

	function convertRangeValue(oldMin,oldMax,newMin,newMax,value){
		var oldRange = (oldMax - oldMin);
		var newRange = (newMax - newMin);
		var newValue = (((value - oldMin) * newRange) / oldRange) + newMin;

		if (oldRange <= 0){
			newValue = 10;
		}
		return newValue;
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

	function setaDadosAbertos(){

		$("#button-download").click(function(){
			if ($(".share-link").is(":visible")){
				$(".share-link").toggle();
				$("#button-share").toggleClass("down");
			}
			$(".download-links").toggle();
			$(this).toggleClass("down");
		});


		$("#button-share").click(function(){
			if ($(".download-links").is(":visible")){
				$(".download-links").toggle();
				$("#button-download").toggleClass("down");
			}
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

		$(".download-links").empty();
		$(".download-links").append("<div class='label'>Tipo:</div>");
		if (ref == "home"){
			$(".download-links").append("<select id='dados-abertos-tipo'><option value='indicadores'>Indicadores</option><option value='variaveis'>Variáveis</option></select>");
		}else{
			$(".download-links").append("<select id='dados-abertos-tipo'><option value='dados'>Dados</option><option value='variaveis'>Variáveis</option></select>");
		}
		$(".download-links").append("<a href='#' class='botao xml' formato='xml'>XML</a>");
		$(".download-links").append("<a href='#' class='botao csv' formato='csv'>CSV</a>");
		$(".download-links").append("<a href='#' class='botao json' formato='json'>JSON</a>");

		$(".download-links a.botao").unbind();
		$(".download-links a.botao").click(function(e){
			e.preventDefault();
			self.location = window.location.href + "/" + $("#dados-abertos-tipo option:selected").val() + "." + $(this).attr("formato");
		});

	}

	if (ref == "comparacao" || ref == "indicador" || ref == "home"){
		carregaIndicadoresCidades();
		setaDadosAbertos();
		$("#share-link").val(window.location.href);
	}

	var History = window.History;

    History.Adapter.bind(window,'statechange',function(){
		if (ref == "comparacao"){
			setaTabs();
			setaGraficos();
		}
		if (ref == "home" || ref == "indicador" || ref == "comparacao"){
			setaDadosAbertos();
			$("#share-link").val(window.location.href);
		}
    });

});