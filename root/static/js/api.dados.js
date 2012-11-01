$(document).ready(function(){

	var combo_uf = [];
	var combo_cidades = [];
	var combo_partidos = [];
	var lista_aberta = "";
	var oDataTable;
	var iDisplayLength = 100;
	var arr_posicoes = [];
	
	var url = [];
	var count_rows = 0;
	var total_rows = 0;
	var geocoder = new google.maps.Geocoder();
	var markers = [];
	var zoom_padrao = 9;
	var graficos = [];
	
	function loadMap(){
		
		var mapOptions = {
				center: mapDefaultLocation,
				zoom: 4,
				mapTypeId: google.maps.MapTypeId.ROADMAP
			};
	
		var map = new google.maps.Map(document.getElementById("mapa"),mapOptions);
	}
	
	function fillCombo(combo,source){
		var first = $(combo).find("option:first");
		$(combo).empty();
		$(combo).append(first);
		
		$.each(source.sort(),function(index,value){
			$(combo).append("<option value='" + value + "'>"+value+"</option>");
		});
	}
	function clearCombo(combo){
		var first = $(combo).find("option:first");
		$(combo).empty();
		$(combo).append(first);
	}
	
	function carregaIndicadores(){
		$.getJSON("json/indicadores.json",
		{
			format: "json"
		},
		function(data) {
			$(".indicators").empty();
			$.each(data.dados, function(i,item){
				$(".indicators").append("<div class='item' indicator-id='$$id'>$$name</div>".render({id: item.id, name: item.name}));
			});
			$(".indicators .item:first").addClass("selected");
			$(".data-right .data-title .title").html($(".indicators .item:first").html());

			$(".indicators .item").click( function (){
				$(".indicators .item").removeClass("selected");
				$(this).addClass("selected");
				$(".data-right .data-title .title").html($(".indicators .selected").html());
				if ($(".data-content .tabs .selected").attr("ref") == "tabela"){
					carregaTabela();
					$(".data-content .table").show();
				}else if ($(".data-content .tabs .selected").attr("ref") == "graficos"){
					carregaGraficos();
				}else{
				}
			});
			carregaTabela();
		});
  	}
	function carregaTabela(){
		var indicador = $(".indicators div.selected").attr("indicator-id");
		$.getJSON("json/indicador." + indicador + ".json",
		{
			format: "json"
		},
		function(data) {
			var table_content = ""
			$(".data-content .table .content-fill").empty();
			table_content += "<table>";
			table_content += "<thead><tr><th>Cidade</th><th>2009</th><th>2010</th><th>2011</th><th>2012</th><th></th></tr></thead>";
			table_content += "<tbody>";
			
			$.each(data.dados, function(i,item){
				table_content += "<tr><td class='cidade'>$$cidade</td>".render({cidade: item.cidade});
				for (j = 0; j < item.valores.length; j++){
					table_content += "<td class='valor'>$$valor</td>".render({valor: item.valores[j]});
				}
				table_content += "<td class='grafico'><canvas id='graph-$$id' width='40' height='20'></canvas></td>".render({id: i});
				graficos[i] = item.valores;
			});

			table_content += "</tbody></table>";
			
			$(".data-content .table .content-fill").append(table_content);
			
			geraGraficos();

		});
  	}
	
	function carregaGraficos(){
		var indicador = $(".indicators div.selected").attr("indicator-id");
		$.getJSON("json/indicador." + indicador + ".json",
		{
			format: "json"
		},
		function(data) {
			
			var colors = ['#124646','#238080','#3cd3d3','#00a5d4','#015b75','#013342'];

			RGraph.Clear(document.getElementById("main-graph"));
			
			var legendas = [];
			
			$.each(data.dados, function(i,item){
				var line = new RGraph.Line('main-graph', item.valores);
				if (i == 0){
					line.Set('chart.labels', ['2009','2010','2011','2012']);
					line.Set('chart.background.grid.vlines', false)
				}else{
		 			line.Set('chart.ylabels', false);
		 			line.Set('chart.noaxes', true);
		 			line.Set('chart.background.grid', false);
				}
				line.Set('chart.colors', [colors[i]]);
				line.Set('chart.tickmarks', 'circle');
				line.Draw();
				legendas.push({name: item.cidade, color: colors[i]});
			});
			
			montaLegenda(legendas);

		});
	}
	
	function montaLegenda(legendas){
		$(".graph .legend").empty();
		
		var legenda = "";
		for (i = 0; i < legendas.length; i++){
			legenda += "<div class='item'><div class='quad' style='background-color: $$color'></div><div class='label' style='color: $$color'>$$label</div></div>".render({label:legendas[i].name, color: legendas[i].color});
		}
		$(".graph .legend").append(legenda);
		
	}
	
	function geraGraficos(){
		for (i = 0; i < graficos.length; i++){
			var line = new RGraph.Line('graph-'+i, graficos[i]);
 			line.Set('chart.ylabels', false);
 			line.Set('chart.noaxes', true);
 			line.Set('chart.background.grid', false);
 			line.Set('chart.hmargin', 0);
 			line.Set('chart.gutter.left', 0);
 			line.Set('chart.gutter.right', 0);
 			line.Set('chart.gutter.top', 0);
 			line.Set('chart.gutter.bottom', 0);
 			line.Set('chart.colors', ['#b4b4b4']);
            line.Draw();
		}
	}

	$(".data-content .tabs .item").click( function (){
		$(".data-content .tabs .item").removeClass("selected");
		$(this).addClass("selected");
		if ($(this).attr("ref") == "tabela"){
			$(".data-content .graph").hide();
			$(".data-content .map").hide();
			carregaTabela();
			$(".data-content .table").show();
		}else if ($(this).attr("ref") == "graficos"){
			$(".data-content .table").hide();
			$(".data-content .map").hide();
			carregaGraficos();
			$(".data-content .graph").show();
		}else{
			$(".data-content .table").hide();
			$(".data-content .graph").hide();
			$(".data-content .map").show();
		}
	});

	carregaIndicadores();

});
