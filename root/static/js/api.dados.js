var indicadores_list;
var eixos_list = {
    "dados": []
};
var users_list;
var indicadorID;
var indicadorID_origin = indicadorID;
var StateDataDefault;
var indicadorDATA;
var dadosGrafico;

var heatCluster;
var carregouTabela = false;
var carregaVariacoes = true;
var ano_atual_dados;

var dados_mapa;
$(document).ready(function () {


    $.ajaxSetup({
        cache: false
    });

    var graficos = [];

    function carregaIndicadoresCidades() {

        $.ajax({
            type: 'GET',
            dataType: 'json',
            url: api_path + '/api/public/network?user_id=$$user_id'.render({
                user_id: userID
            }),
            success: function (data, textStatus, jqXHR) {
                users_list = [];
                indicadores_list = data.indicators;

                $(data.users).each(function (index, item) {
                    if (item.id == userID) {cidade_uri = "/" + item.city.pais + "/" + item.city.uf + "/" + item.city.name_uri;}
                    users_list.push({
                        id: item.id,
                        nome: item.city.name,
                        pais: item.city.pais,
                        uf: item.city.uf,
                        uri: item.city.name_uri,
                        label: item.city.name + " - " + item.city.uf
                    });
                });

                users_list.sort(function (a, b) {
                    a = a.nome;
                    b = b.nome;

                    return a.localeCompare(b);
                });

                $(indicadores_list).each(function (index, value) {
                    if (!findInJson(eixos_list.dados, "id", value.axis.id).found) {
                        eixos_list["dados"].push({
                            id: value.axis.id,
                            name: value.axis.name
                        });
                    }
                });

                carregaIndicadores();
            },
            error: function (data) {
                console.log("erro ao carregar informações dos indicadores");
            }
        });
    }

    function carregaIndicadores() {
        /*
        $("#group_list").empty();

        eixos_list.dados.sort(function (a, b) {
            a = a.name,
            b = b.name;

            return a.localeCompare(b);
        });

        $(eixos_list.dados).each(function(index,value){
            if (index === 0){
                $("#group_list").append("<div class='select' axis-id='0'><div class='content-fill'>Categoria</div></div>");
                $("#group_list").append("<div class='options'><div class='option' axis-id='0'>Categoria</div></div>");
            }
            $("#group_list .options").append("<div class='option' axis-id='$$id'>$$nome</div>".render({
                            id: value.id,
                            nome: value.name
                }));
        });

        $("#group_list .select").click(function(){
            $("#group_list .options").toggle();
        });
        $("#group_list .option").click(function(){
            $("#group_list .select").attr("axis-id",$(this).attr("axis-id"));
            $("#group_list .select .content-fill").html($(this).html());
            $("#group_list .options").hide();
            if ($(this).attr("axis-id") != 0){
                $(".menu-left div.indicators .item").hide();
                $(".menu-left div.indicators .item[axis-id='$$axis_id']".render({axis_id: $(this).attr("axis-id")})).show();
            }else{
                $(".menu-left div.indicators .item").show();
            }
            $("#indicator-search").val("");

        });
        $("#group_list .options").hover(function(){
            if (typeof(t_categorias) != "undefined"){
                if (t_categorias){
                    clearTimeout(t_categorias);
                }
            }
        },function(){
            t_categorias = setTimeout(function(){
                $("#group_list .options").hide();
            },2000) ;
        });

        $("#indicator-search").keyup(function(){
            if ($(this).val() != ""){
                $(".indicators .item").hide();
                var termo = $(this).val();
                var matches = $('.indicators .item').filter(function() {
                    var match = normalize(termo);

                    var pattern = match;
                    var re = new RegExp(pattern,'g');

                    return re.test( normalize($(this).text()) );
                });
                if ($("#group_list .select").attr("axis-id") != 0 && $("#group_list .select").attr("axis-id") != ""){
                    $(matches).each(function(index,element){
                        if ($(this).attr("axis-id") == $("#group_list .select").attr("axis-id")){
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
            $("#group_list .options").hide();
            if ($("#group_list .select").attr("axis-id") != 0){
                $(".menu-left div.indicators .item").hide();
                $(".menu-left div.indicators .item[axis-id='$$axis_id']".render({axis_id: $("#group_list .select").attr("axis-id")})).show();
            }else{
                $(".menu-left div.indicators .item").show();
            }
            if ($("#indicator-search").val() != ""){
                $(".indicators .item").hide();
                var termo = $("#indicator-search").val();
                var matches = $('.indicators .item').filter(function() {
                    var match = normalize(termo);

                    var pattern = match;
                    var re = new RegExp(pattern,'g');

                    return re.test( normalize($(this).text()) );
                });
                if ($("#group_list .select").attr("axis-id") != 0 && $("#group_list .select").attr("axis-id") != ""){
                    $(matches).find("[axis-id='$$axis_id']".render({axis_id: $("#group_list .select").attr("axis-id")})).fadeIn();
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
            $(".indicators").append("<div class='item bs-tooltip' data-toggle='tooltip' data-placement='right' title data-original-title='$$explanation' indicator-id='$$id' axis-id='$$axis_id' name-uri='$$uri'>$$name</div>".render({
                        id: item.id,
                        name: item.name,
                        axis_id: item.axis.id,
                        uri: item.name_url,
                        explanation: (item.explanation) ? item.explanation : ""
                    }));
        });
        $("div.bs-tooltip").tooltip();
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


        $(".indicators .item").click( function (){

            if ($(".indicators").hasClass("meloading")){
                alert('Por favor, espere o indicador carregar.');
                return;
            }
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
            $(".indicators").addClass("meloading");
            $(this).addClass("selected");

            var title = $(".indicators .selected").text();

            if ($(window).scrollTop() > 130){
                $('html,body').animate({scrollTop: 130},'slow');
            }

            var url;
            if (ref == "comparacao"){
                url = "/" + $(this).attr("name-uri") + $.getUrlParams();

                History.pushState(null, title, url);

            }else if (ref == "indicador" ){
                url = "/"+cidade_uri + "/" + $(this).attr("name-uri") + $.getUrlParams();
                History.pushState({
                    indicator_id: indicadorID
                }, title, url);
            }else if (ref == "region_indicator"){
                url = "/"+cidade_uri + "/regiao/" +  region_name_url + "/" + $(this).attr("name-uri") + $.getUrlParams();
                History.pushState({
                    indicator_id : indicadorID
                }, title, url);
            }

            ga('send', 'pageview', url);
        });
*/

    }

    function activeMenuOfIndicator(id) {
        /*
        indicadorID = id;
        selectAxis(id);

        $(".indicators .item").removeClass("selected");
        $(".indicators .item[indicator-id='$$indicator_id']".render({indicator_id: indicadorID})).addClass("selected");

        $(".data-right .data-title .title").html($(".indicators .item[indicator-id='$$indicator_id']".render({indicator_id: indicadorID})).html());
        $(".data-right .data-title .description").html((indicadorDATA.explanation) ? indicadorDATA.explanation : "");
*/
    }

    function carregaDadosTabela() {

        if (!carregouTabela) {
            $.xhrPool.abortAll();
            $(".indicators").addClass("meloading");

            var indicador = indicadorID;
            var indicador_uri = $(".indicators div.selected").attr("name-uri");

            var ymd_atual = ano_atual_dados.split('-');

            var data_atual = new Date(ymd_atual[0], ymd_atual[1], ymd_atual[2]);
            var ano_anterior = data_atual.getFullYear() + 3;
            var date_labels = [];


            if (indicadorDATA.indicator_type == "varied") {
                if (carregaVariacoes) {
                    montaFiltroVariacao();
                }
            } else {
                removeFiltroVariacao();
            }


            var table_content = "";
            $(".data-content .table .content-fill").empty();
            table_content += "<table id='table-data'>";
            table_content += "<thead><tr><th>Cidade</th>";
            data_atual = new Date(ymd_atual[0], ymd_atual[1], ymd_atual[2]);
            ano_anterior = data_atual.getFullYear() + 3;
            for (i = ano_anterior - 3; i <= ano_anterior; i++) {
                table_content += "<th>" + i + "</th>";
            }
            table_content += "<th>&nbsp;</th></tr></thead>";
            table_content += "<tbody>";
            table_content += "</tbody></table>";
            $(".data-content .table .content-fill").append(table_content);

            var total_users = users_list.length;
            var users_ready = 0;
            var total_visible = 0;
            $(users_list).each(function (index, item) {

                $.ajax({
                    type: 'GET',
                    dataType: 'json',
                    url: api_path + '/api/public/user/$$userid/indicator/$$indicatorid/chart/period_axis?from=$$from&to=$$to'.render({
                        userid: item.id,
                        indicatorid: indicador,
                        from: ano_atual_dados,
                        to: ano_anterior + '-01-01'
                    }),
                    success: function (data, textStatus, jqXHR) {

                        if (indicadorDATA.indicator_type == "varied") {
                            if ($("#variationFilter option").length <= 0) {
                                if ((data.series) && data.series.length > 0) {
                                    $.each(data.series[0].variations, function (index, item) {
                                        $("#variationFilter").append("<option value='$$index'>$$name".render({
                                            index: index,
                                            name: item.name
                                        }));
                                    });
                                    $("#variationFilter").change(function () {
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
                        if (data.series) {
                            for (j = 0; j < data.series.length; j++) {
                                if (indicadorDATA.variable_type == 'str') {
                                    series[data.series[j].label] = data.series[j].data[0][1] == '-' ? '-' : 'OK';
                                } else {
                                    if (indicadorDATA.indicator_type == "varied") {
                                        series[data.series[j].label] = data.series[j].variations[$("#variationFilter").val()].value;
                                    } else {
                                        series[data.series[j].label] = data.series[j].sum;
                                    }
                                }
                            }
                        }

                        var data_atual = new Date(ymd_atual[0], ymd_atual[1], ymd_atual[2]);
                        var ano_anterior = data_atual.getFullYear() + 3;
                        var date_labels = [];

                        var preenchido = 0;
                        for (i = ano_anterior - 3; i <= ano_anterior; i++) {
                            if (series[i] == "-" || series[i] == undefined) {
                                row_content += "<td class='valor'>-</td>";
                                valores.push(null);
                            } else {
                                if (indicadorDATA.variable_type == 'str') {
                                    row_content += "<td class='valor'>$$valor</td>".render({
                                        valor: series[i]
                                    });
                                    preenchido++;
                                } else {
                                    var format_value = parseFloat(series[i]);
                                    var format_string = "#,##0.##";
                                    if (format_value.toFixed(2) === 0) {
                                        format_string = "#,##0.###";
                                    }
                                    row_content += "<td class='valor'>$$valor</td>".render({
                                        valor: $.formatNumberCustom(series[i], {
                                            format: format_string,
                                            locale: "br"
                                        })
                                    });
                                    preenchido++;
                                }
                                valores.push(parseFloat(series[i]).toFixed(2));
                            }
                        }

                        row_content += "<td class='grafico'><a href='#' user-id='$$data_id'><canvas id='graph-$$id' width='40' height='20'></canvas></a></td>".render({
                            id: index,
                            data_id: item.id
                        });

                        var $it = $(row_content);
                        $(".data-content .table .content-fill tbody").append($it);
                        if (preenchido === 0) {
                            //$it.hide();
                        } else {
                            total_visible++;
                        }

                        if (indicadorDATA.variable_type == 'str') {
                            $("td.grafico a").hide();
                            $('#tab-mapa').hide();
                            $('#tab-graficos').hide();
                        } else {
                            $('#tab-mapa').show();
                            $('#tab-graficos').show();
                        }



                        //alimenta dados dos graficos
                        graficos[index] = valores;
                        /*
                        dadosGrafico.dados.push({
                            id: item.id,
                            nome: item.nome,
                            valores: valores,
                            data: data,
                            show: false,
                            latitude: data.city.latitude,
                            longitude: data.city.longitude
                        });
                */

                        //alimenta dados do mapa

                        users_ready++;

                        if (users_ready >= total_users) {



                            if (!(typeof google == "undefined")) {
                                geraMapa();
                            }
                            if (total_visible === 0) {
                                $(".data-content .table .content-fill tbody").append('<tr><td colspan="20">Nenhuma cidade preencheu este indicador!</td></tr>');
                            }

                            carregouTabela = true;
                            $(".indicators").removeClass("meloading");
                        }


                    },
                    error: function (data) {
                        console.log("erro ao carregar informações do indicador");
                    }
                });

            });
        }
    }

    function montaFiltroVariacao() {
        $(".data-content .variationFilter").remove();
        $(".data-content .tabs").before("<div class='variationFilter'>Selecione uma Faixa: <select id='variationFilter'></select></div>");
    }

    function removeFiltroVariacao() {
        $(".data-content .variationFilter").remove();
    }

    function reload_bind_content() {

        if (heatCluster) {
            heatCluster.setMap(null);
        }
        map = undefined;


        dados_mapa = $('#map').attr('data-json') ? $.parseJSON($('#map').attr('data-json')) : {};
        dadosGrafico = $('#graph').attr('data-json') ? $.parseJSON($('#graph').attr('data-json')) : {};
        $('#mapa-filtro-periodo').change(function () {
            var $me = $(this).val(),
                $dados = dados_mapa[$me];

            if (typeof $dados == 'undefined') {
                $dados = [];
            }
            geraMapa($dados);
        });

        $('a[href="#table"]').on('shown', function (e) {
            $.setUrl({
                view: "table"
            }, {
                recontent: false
            });
        });

        $('a[href="#map"]').on('shown', function (e) {
            $.setUrl({
                view: "map"
            }, {
                recontent: false
            });
            if (!map) {
                $('#mapa-filtro-periodo').change();
            }
        });

        $('a[href="#graph"]').on('shown', function (e) {
            $.setUrl({
                view: "graph"
            }, {
                recontent: false
            });
            setaGraficos();
        });

        if (ref == 'comparacao') {
            indicadorDATA = $.parseJSON($('#indicador-dados').attr('data-json'));

            $("td button.compare").on('click', function (e) {
                var graphs;
                if ($.getUrlVar("graphs")) {
                    graphs = $.getUrlVar("graphs").split("-");
                } else {
                    graphs = [];
                }

                var tr = $(this).parents('tr:first'),
                    id = tr.attr("data-user-id");
                if (!findInArray(graphs, id)) {
                    graphs.push(id);
                }

                e.preventDefault();
                $.setUrl({
                    graphs: graphs.join("-"),
                    view: "graph"
                }, {
                    recontent: false
                });
                if ($(window).scrollTop() > 554) {
                    $('html,body').animate({
                        scrollTop: 554
                    }, 'fast');
                }

            });
        }
    }
    reload_bind_content();



    $.carregaGrafico = function (canvasId) {
        _resize_canvas();
        RGraph.ObjectRegistry.Clear();
        var color_meta = '#ff0000';
        var colors = [
            '#009d56', '#96746a', '#00a5d4', '#84a145', '#f69a57', '#46489e', '#a1214a', '#7475b6', '#696a6c', '#4099f0'
        ];

        colors = colors.concat(colors, colors, colors, colors, colors, colors, colors, colors, colors, colors, colors, colors);

        var legendas = [];
        var linhas = [];
        var tooltips = [];

        var ymax, ymin, maxlength;
        if (indicadorDATA.goal) {

            var $maximo_linhas = dadosGrafico.labels.length;

            $.each(dadosGrafico.dados, function (i, item) {
                if (item.show) {
                    if (item.valores.length > $maximo_linhas) {
                        $maximo_linhas = item.valores.length;
                    }
                }
            });

            var $labels = new Array();
            for (var $i = 0; $i < $maximo_linhas; $i++) {
                $labels.push(indicadorDATA.goal);
            }
            linhas.push($labels);

            for ($i = 0; $i < $maximo_linhas; $i++) {
                tooltips.push(indicadorDATA.goal);
            }

            legendas.push({
                name: "Referência de Meta",
                color: color_meta,
                meta: true
            });

            ymax = indicadorDATA.goal;
            ymin = indicadorDATA.goal;
            maxlength = indicadorDATA.goal.length;
        } else {
            ymin = 0;
            ymax = 0;
            maxlength = 1;
        }

        var color_index = 0;
        $.each(dadosGrafico.dados, function (i, item) {
            if (item.show) {
                linhas.push(item.valores);
                legendas.push({
                    name: item.nome,
                    color: colors[color_index],
                    id: item.id
                });
                $.each(item.valores, function (index, valor) {
                    if (valor != null) {
                        if (ymin === 0) ymin = parseFloat(valor);
                        if (parseFloat(valor) < ymin) ymin = parseFloat(valor);

                        if (ymax === 0) ymax = parseFloat(valor);
                        if (parseFloat(valor) > ymax) max = parseFloat(valor);

                        if (String(valor).length > maxlength) maxlength = String(valor).length;

                        tooltips.push(parseFloat(valor).toFixed(2));
                    } else {
                        tooltips.push(" "); //jogar valor em branco na tooltip caso a sequencia nao tenha valor
                    }
                });
                color_index++;
            }
        });


        if (maxlength < 10){ maxlength = 10;}

        if ((ymin >= 0) && ((parseInt(ymin, 10) - 1) < 0)) {
            ymin = 0;
        } else {
            ymin = parseInt(ymin,10) - 1;
        }

        ymin = 0;

        if (indicadorDATA.goal) {
            colors.unshift(color_meta);
        }

        var line = new RGraph.Line(canvasId, linhas);
        RGraph.Clear(line.canvas);
        line.Set('chart.tooltips', tooltips);
        line.Set('chart.labels', dadosGrafico.labels);
        line.Set('chart.ymin', ymin);
        line.Set('chart.gutter.left', maxlength * 5);
        line.Set('chart.text.font', 'tahoma');
        line.Set('chart.text.color', '#bbbbbb');
        line.Set('chart.axis.color', '#bbbbbb');
        line.Set('chart.colors', colors);
        line.Set('chart.tickmarks', 'filledcircle');
        line.Draw();

        montaLegenda({
            source: legendas,
            removable: true
        });
    };

    function setGraphLine(id, status) {
        $.each(dadosGrafico.dados, function (index, item) {
            if (item.id == id) {
                dadosGrafico.dados[index].show = status;
            }
        });
    }

    function clearGraphLines() {
        $.each(dadosGrafico.dados, function (index, item) {
            dadosGrafico.dados[index].show = false;
        });
    }

    function montaLegenda(args) {
        var legendas = args.source;
        $(".graph .legend").empty();

        var legenda = "";
        for (i = 0; i < legendas.length; i++) {
            var sClass;
            if (legendas[i].meta) {
                sClass = "item meta";
            } else {
                sClass = "item";
            }
            legenda += "<div class='$$sclass'><div class='quad' style='background-color: $$color'></div><div class='label' style='color: $$color'>$$label</div><div class='close'><div class='icon' item-id='$$id' title='Remover' alt='Remover'>x</div></div></div>".render({
                label: legendas[i].name,
                color: legendas[i].color,
                sclass: sClass,
                id: legendas[i].id
            });
        }
        $(".graph .legend").append(legenda);


        if (args.removable) {

            $(".graph .legend .item").hover(function () {
                if (!$(this).hasClass("meta")) {
                    $(this).find(".icon").fadeIn();
                }
            }, function () {
                if (!$(this).hasClass("meta")) {
                    $(this).find(".icon").hide();
                }
            });

            $(".graph .legend .icon").click(function () {
                if ($(this).attr("item-id")) {
                    var graphs;
                    if ($.getUrlVar("graphs")) {
                        graphs = $.getUrlVar("graphs").split("-");
                    } else {
                        graphs = [];
                    }

                    graphs = $.removeItemInArray(graphs, $(this).attr("item-id"));

                    $.setUrl({
                        graphs: graphs.join("-")
                    }, {
                        recontent: false
                    });

                }
            });
        }

    }




    function setaGraficos() {
        if ($.getUrlVar("graphs")) {
            clearGraphLines();
            var graphs = $.getUrlVar("graphs").split("-");
            $.each(graphs, function (index, value) {
                setGraphLine(value, true);
            });
        } else {
            clearGraphLines();
        }
        $.carregaGrafico("main-graph");
    }

    function geraMapa($dados) {

        if (!map) {
            map = new google.maps.Map(document.getElementById('mapa'), {
                mapTypeId: google.maps.MapTypeId.ROADMAP
            });
        }

        if (heatCluster) {
            heatCluster.setMap(null);
        }

        var markers = [];

        var bounds = new google.maps.LatLngBounds();
        $.each($dados, function (index, item) {
            if (item.lng) {
                var valor = parseFloat(item.val);
                if (valor) {
                    var latLng = new google.maps.LatLng(item.lat, item.lng);
                    markers.push({
                        location: latLng,
                        weight: valor
                    });
                    bounds.extend(latLng);
                }
            }
        });

        map.fitBounds(bounds);

        var pointArray = new google.maps.MVCArray(markers);
        heatCluster = new google.maps.visualization.HeatmapLayer({
            data: pointArray,
            radius: 30
        });
        heatCluster.setMap(map);

    }

    function customClusterText(markers, numStyles) {

        var text;
        var title;

        var index = 0;
        var count = markers.length;
        var dv = count;
        while (dv !== 0) {
            dv = parseInt(dv / 10, 10);
            index++;
        }

        index = Math.min(index, numStyles);

        if (markers.length > 0) {
            text = $.formatNumberCustom(markers[0].__valor, {
                format: "#,##0.##",
                locale: "br"
            });
            title = markers[0].__nome + " - " + text;
        } else {
            text = count;
        }

        return {
            text: text,
            index: index,
            title: title
        };

    }

    function convertRangeValue(oldMin, oldMax, newMin, newMax, value) {
        var oldRange = (oldMax - oldMin);
        var newRange = (newMax - newMin);
        var newValue = (((value - oldMin) * newRange) / oldRange) + newMin;

        if (oldRange <= 0) {
            newValue = 10;
        }
        return newValue;
    }


    function selectAxis(id) {
        /*var indicador = $(".indicators .item[indicator-id='$$id']".render({id: id}));

        var eixo = $("#group_list .option[axis-id='$$id']".render({id: $(indicador).attr("axis-id")}));
        $("#group_list .select").attr("axis-id",$(eixo).attr("axis-id"));
        $("#group_list .select .content-fill").html($(eixo).html());
        $("#group_list .options").hide();

        if ($(eixo).attr("axis-id") != 0){
            $(".menu-left div.indicators .item").hide();
            $(".menu-left div.indicators .item[axis-id='$$axis_id']".render({axis_id: $(eixo).attr("axis-id")})).show();
        }else{
            $(".menu-left div.indicators .item").show();
        }*/

    }

    function setaDadosAbertos() {

        $("#button-download").unbind();
        $("#button-download").click(function () {
            if ($(".share-link").is(":visible")) {
                $(".share-link").toggle();
                $("#button-share").toggleClass("down");
            }
            $(".download-links").toggle();
            $(this).toggleClass("down");
        });


        $("#button-share").unbind();
        $("#button-share").click(function () {
            if ($(".download-links").is(":visible")) {
                $(".download-links").toggle();
                $("#button-download").toggleClass("down");
            }
            $(".share-link").toggle();
            $(this).toggleClass("down");
            $("#share-link").select();
        });
        $("#share-link").focus(function () {
            $(this).select();
        });
        $("#share-link").unbind();
        $("#share-link").click(function () {
            $(this).select();
        });
        $("#share-link").keypress(function (e) {
            e.preventDefault();
        });

        $(".download-links").empty();
        $(".download-links").append("<div class='label'>Tipo:</div>");
        if (ref == "home") {
            $(".download-links").append("<select id='dados-abertos-tipo'><option value='indicadores'>Indicadores</option><option value='variaveis'>Variáveis</option></select>");
        } else {
            $(".download-links").append("<select id='dados-abertos-tipo'><option value='dados'>Dados</option><option value='variaveis'>Variáveis</option></select>");
        }
        $(".download-links").append("<a href='#' class='botao xml' formato='xml'>XML</a>");
        $(".download-links").append("<a href='#' class='botao csv' formato='csv'>CSV</a>");
        $(".download-links").append("<a href='#' class='botao csv' formato='xls'>XLS</a>");
        $(".download-links").append("<a href='#' class='botao json' formato='json'>JSON</a>");

        $(".download-links a.botao").unbind();
        $(".download-links a.botao").click(function (e) {
            e.preventDefault();
            var x = 'http://' + window.location.host + window.location.pathname;
            if (x.substr(-1, 1) != '/'){
                x = x + '/';}

            self.location = x + $("#dados-abertos-tipo option:selected").val() + "." + $(this).attr("formato");
        });

    }

    if (ref == "comparacao" || ref == "indicador" || ref == "home" || ref == "region_indicator") {
        carregaIndicadoresCidades();
        setaDadosAbertos();
        $("#share-link").val(window.location.href);
    }

    var History = window.History;

    History.Adapter.bind(window, 'statechange', function () {
        var State = History.getState();

        State.data = State.data == null ? {} : State.data;


        if (ref == "home" || ref == "indicador" || ref == "comparacao" || ref == "region_indicator") {
            if (!State.data.indicator_id) {
                State.data.indicator_id = indicadorID_origin;
            }

            setaDadosAbertos();
            $("#share-link").val(window.location.href);

            if (ref == "region_indicator" || ref == "indicador") {

                activeMenuOfIndicator(State.data.indicator_id);

                $.loadCidadeDataIndicador();
            }
        }

        if (typeof State.data.recontent == "undefined"){
            State.data.recontent = true;}

        if (State.data.recontent) {
            $(".indicators").addClass("meloading");
            $('[data-part-onchange-location]').each(function (a, b) {
                var $me = $(b),
                    part = $me.attr('data-part-onchange-location');
                var newURL = updateURLParameter(window.location.href, 'part', part);

                $.ajax({
                    url: newURL,
                    cache: true
                }).done(function (data) {
                    var $c = $(data);

                    $me.replaceWith($c);

                    initialize_maps();

                    if (part == 'comparacao_indicador_por_cidade') {
                        $(".indicators").removeClass("meloading");
                        reload_bind_content();
                        _after_recontent();

                        activeMenuOfIndicator(indicadorDATA.id);
                    }

                    var $it = $me.find('a[data-toggle="tab"]');
                    if ($it[0]) {
                        $('html').find('a[data-toggle="tab"]').on('shown', _on_func);
                        $(".indicators").removeClass("meloading");
                    }
                });

            });

        } else {

            if (ref == "comparacao") {
                var view = $.getUrlVar('view');
                if (view) {
                    $('a[href="#' + view + '"]').tab('show');
                } else {
                    $('a[href="#table"]').tab('show');
                }
                setaGraficos();
            }

        }
    });


    function _bind_tables() {
        $('[stupidsort]').each(function (x, rlm) {
            var table = $(rlm).stupidtable({
                myfloat: function (x, y) {
                    if (x == y) {return 0;}
                    if (x == "") {return -1;}
                    if (y == "") {return 1;}

                    if (parseFloat(x) > parseFloat(y)) {return 1;}
                    return -1;
                }
            });

            table.bind('aftertablesort', function (event, data) {
                var th = $(this).find("th");
                th.find(".arrow").remove();
                var arrow = data.direction === "asc" ? "↑" : "↓";
                th.eq(data.column).append('<span class="arrow">' + arrow + '</span>');

                $('#alert_variation_missorder').removeClass('hidden');

            });

        });

    }

    function _on_load() {
        $('[lockfixed]').each(function (x, rlm) {
            $.lockfixed(rlm, {
                offset: {
                    top: 47,
                    bottom: 10
                }
            });
        });
    }

    function _after_recontent() {

        _bind_tables();

        $("#graph-search-user").autocomplete({
            source: function (request, response) {
                var matcher = new RegExp($.ui.autocomplete.escapeRegex(request.term), "i");
                response($.grep(users_list, function (value) {
                    value = value.label || value.value || value;
                    return matcher.test(value) || matcher.test(normalize(value));
                }));
            },
            focus: function (event, ui) {
                $("#button-search-user").attr("disabled", true);
            },
            select: function (event, ui) {
                $("#graph-user-selected").val(ui.item.id);
                $("#button-search-user").attr("disabled", false);
            }
        });

        $('#variation_checks input').on('change', function () {
            var $me = $(this);
            $('#table_cmp_user tr.varied[data-variation="' + $me.val() + '"]')[$me.is(':checked') ? 'addClass' : 'removeClass']('active');
        });
        $("#button-search-user").click(function () {

            var graphs ;
            if ($.getUrlVar("graphs")) {
                graphs = $.getUrlVar("graphs").split("-");
            } else {
                graphs = [];
            }

            if (!findInArray(graphs, $("#graph-user-selected").val())) {
                graphs.push($("#graph-user-selected").val());
            }

            $.setUrl({
                graphs: graphs.join("-")
            }, {
                recontent: false
            });
            $("#graph-search-user").val("");
        });

        var view = $.getUrlVar('view');
        if (view) {
            $('a[href="#' + view + '"]').trigger('shown');
        }

    }

    _on_load();
    _after_recontent();



});