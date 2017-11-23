var zoom_padrao = 5;
var map;
var boxText;
var myOptions;
var ib;
var cidade_data;
var is_infancia;
var indicadores_data;
var graficos = [];
var dimensions_GO = {
    "1": "Sustentabilidade Ambiental e Mudança Climática",
    "2": "Sustentabilidade Fiscal e Governabilidade",
    "3": "Sustentabilidade Urbana"
};

var functions = {};
$(document).ready(function() {
    institute_info = $.parseJSON($('body').attr('data-institute'));

    function loadCidadeData() {


        if ($('#cidades-indicadores')[0]) {
            loadIndicadoresData();
        }
        if (!(typeof google == "undefined")) {
            loadMap();
        }
        $.ajax({
            type: 'GET',
            dataType: 'json',
            url: api_path + '/api/public/user/$$id'.render({
                id: userID
            }),
            success: function(data, textStatus, jqXHR) {
                cidade_data = data;
                showCidadeData();
            },
            error: function(data) {
                alert("erro ao carregar informações da cidade");
            }
        });
    }

    function loadMap() {

        if (document.getElementById("map_canvas")){
            loadMapInfancia();
            return 1;
        }

        if (!document.getElementById("mapa")){
            return 0;
        }


        var mapDefaultLocation = new google.maps.LatLng(-14.2350040, -51.9252800);
        var geocoder = new google.maps.Geocoder();

        var mapOptions = {
            center: mapDefaultLocation,
            zoom: zoom_padrao,
            mapTypeId: google.maps.MapTypeId.ROADMAP,
            draggable: false,
            scrollwheel: false,
            navigationControl: false,
            mapTypeControl: false,
            scaleControl: false,
            zoomControl: false,
            streetViewControl: false,
            fullscreenControl: false,
        };

        map = new google.maps.Map(document.getElementById("mapa"), mapOptions);

        boxText = document.createElement("div");
        boxText.style.cssText = "border: 2px solid #20c1c1; margin-top: 8px; background: white; padding: 0px;";
        boxText.innerHTML = "";
        myOptions = {
            content: boxText,
            disableAutoPan: false,
            maxWidth: 0,
            pixelOffset: new google.maps.Size(-100, 0),
            zIndex: null,
            boxStyle: {
                background: "url('/static/images/tipbox.gif') no-repeat",
                opacity: 0.90,
                width: "200px"
            },
            closeBoxMargin: "10px 2px -13px 2px",
            closeBoxURL: "http://www.google.com/intl/en_us/mapfiles/close.gif",
            infoBoxClearance: new google.maps.Size(1, 1),
            isHidden: false,
            pane: "floatPane",
            enableEventPropagation: false
        };

        ib = new InfoBox(myOptions);

        ib.close();

    }

    function setMap(lat, lng) {
        if (document.getElementById("map_canvas")){
            return 0;
        }
        if (!map) return 0;

        var center = new google.maps.LatLng(lat, lng);
        map.setCenter(center);

        var image = new google.maps.MarkerImage("/static/images/pin.png");

        var marker = new google.maps.Marker({
            position: center,
            map: map,
            icon: image,
        });

        marker.__position = center;

        google.maps.event.addListener(marker, 'mouseover', function(e) {
            map.setCenter(marker.__position);
            if (map.getZoom() < zoom_padrao) {
                map.setZoom(zoom_padrao);
            }
            showInfoWindow(marker, "marker");
        });


    }

    function showInfoWindow(marker, source) {
        boxTextContent = "<table class='infowindow'><thead>";
        boxTextContent += "<tr>";
        boxTextContent += "<th>Prefeitura</th>";
        boxTextContent += "</tr></thead>";
        boxTextContent += "<tbody>";
        boxTextContent += "<tr>";
        if (cidade_data.cidade.endereco_prefeitura !== null || cidade_data.cidade.telefone_prefeitura !== null) {
            boxTextContent += "<td>" + cidade_data.cidade.endereco_prefeitura + "<br />" + cidade_data.cidade.telefone_prefeitura + "</td>";
        } else {
            boxTextContent += "<td>Dados não informados</td>";
        }
        boxTextContent += "</tr>";
        boxTextContent += "</tbody></table>";

        boxText.innerHTML = boxTextContent;
        ib.close();
        ib.setContent(boxText);
        ib.open(map, marker);
    }

    function showCidadeData() {

        $("#cidades-dados .profile .title").html(cidade_data.cidade.name + ", " + cidade_data.cidade.uf);
        if (cidade_data.usuario.city_summary) {
            $("#cidades-dados .summary .content-fill").html(cidade_data.usuario.city_summary);
        }

        $tabela = $('dl.tabela');
        var user_files = cidade_data.usuario.files;
        if (institute_short_name === 'gov') {

            $tabela.append("<dt>Documentos</dt>");

            if (typeof(user_files.carta_compromis) != "undefined") {
                $tabela.append("<dd><a href='$$dado' target='_blank'>Carta compromisso</a></dd>".render({
                    dado: user_files.carta_compromis
                }));
            } else {
                $tabela.append("<dd>Carta compromisso (não disponível)</dd>");
            }

            if (typeof(user_files.prestacao_de_co) != "undefined") {
                $tabela.append("<dd><a href='$$dado' target='_blank'>Relatório de prestação de contas</a></dd>".render({
                    dado: user_files.prestacao_de_co
                }));
            } else {
                $tabela.append("<dd>Relatório de prestação de contas (não disponível)</dd>");
            }

            if (typeof(user_files.arq_lei) != "undefined") {
                $tabela.append("<dd><a href='$$dado' target='_blank'><img src='http://icon-icons.com/icons2/775/PNG/512/bill_icon-icons.com_64622.png' width='26' alt='Arquivo de lei' /> Arquivo de lei</a></dd>".render({
                    dado: user_files.arq_lei
                }));
            }

            if (typeof(user_files.programa_metas) != "undefined") {
                $tabela.append("<dd><a href='$$dado' target='_blank'>Plano de Metas</a></dd>".render({
                    dado: user_files.programa_metas
                }));
            } else {
                $tabela.append("<dd>Plano de Metas (não disponível)</dd>");
            }

        }


        if (typeof(user_files.imagem_cidade) != "undefined" && $("#cidades-dados .image")[0]) {
            $("#cidades-dados .image").html('<img/>');
            $("#cidades-dados .image img")[0].src = user_files.imagem_cidade;
        } else {
            $("#cidades-dados .image").html('<div class="alert alert-block"><p>Cidade sem imagem!</p></div>');
        }

        //var diff = $("#cidades-dados .profile .content-fill").height() - $("#cidades-dados .profile").height() + 10;
        //if (diff > 10){
        //  $("#cidades-dados .profile").css("height","+="+diff);
        //      $("#cidades-dados .summary").css("height","+="+diff);
        //      $("#cidades-dados .map").css("height","+="+diff);
        //      $("#cidades-dados #mapa").css("height","+="+diff);
        //  }

        if (!(typeof google == "undefined")) {
            if (cidade_data.cidade.latitude !== null && cidade_data.cidade.longitude !== null) {
                setMap(cidade_data.cidade.latitude, cidade_data.cidade.longitude);
            }
        }

    }

    function loadIndicadoresData() {
        var param = typeof regionID == "undefined" ? '?without_topic=1' : '?without_topic=1&region_id=' + regionID,

            qparams = $.getUrlVars();

        if (qparams) {
            var date = qparams.valid_from_desc;

            if (date) {
                var date_parser = date.split("-");

                date_parser[0] = parseInt(date_parser[0]) + 1;

                date = date_parser.join("-");

                param = param + '&' + 'from_date=' + date;
            }

            if (is_infancia) {
                param += '&include_other_dims=1';
            }

            if (qparams.axis_dim2) {
                param += '&axis_dim2=' + qparams.axis_dim2;
            }

            if (qparams.axis_dim3) {
                param += '&axis_dim3=' + qparams.axis_dim3;
            }
        }


        $.ajax({
            type: 'GET',
            dataType: 'json',
            url: (api_path + '/api/public/user/$$id/indicator' + param).render({
                id: userID
            }),
            success: function(data, textStatus, jqXHR) {
                indicadores_data = data;
                showIndicadoresData();
            },
            error: function(data) {
                alert("erro ao carregar indicadores da cidade");
            }
        });
    }
    functions['loadIndicadoresData'] = loadIndicadoresData;

    function replaceAll(find, replace, str) {
        return str.replace(new RegExp(find, 'g'), replace);
    }

    function showIndicadoresData() {
        var table_content = '<table class="table table-striped table-hover">';
        $("#cidades-indicadores .table").empty();

        var cont = 0;

        var eixos_ordem = [];

        var eixos_indicadores = [];

        var dimension_id;


        if (indicadores_data.dimensions) {
            dimensions_GO = indicadores_data.dimensions;
        }

        $.each(indicadores_data.resumos, function(index, item) {

            if (userID == 763) { //GOIANIA
                if (["Bens Naturais Comuns", "Consumo Responsável e Opções de Estilo de Vida", "Do Local para o Global"].indexOf(index) > -1) {
                    dimension_id = 1;
                } else if (["Fiscal", "Gestão Local para a Sustentabilidade", "Governança"].indexOf(index) > -1) {
                    dimension_id = 2;
                } else if (["Ação Local para a Saúde", "Cultura para a sustentabilidade", "Economia Local, Dinâmica, Criativa e Sustentável", "Educação para a Sustentabilidade e Qualidade de Vida", "Equidade, Justiça Social e Cultura de Paz", "Melhor Mobilidade, Menos Tráfego", "Planejamento e Desenho Urbano"].indexOf(index) > -1) {
                    dimension_id = 3;
                } else {
                    dimension_id = 0;
                }
            } else {
                dimension_id = 0;
            }

            if (index.indexOf("\n\n") > -1) {
                var tmpa = index.split("\n\n");
                dimension_id = tmpa[0]
                index = tmpa[1]
            }


            var new_result = [];
            new_result.dimension_id = dimension_id;
            new_result.name = index;
            new_result.resumo = item;
            new_result.sort_field = dimension_id + index;

            eixos_indicadores.push(new_result);
        });

        eixos_indicadores.sort(function(a, b) {
            if (b.name === 'Indicadores da cidade') return -1;
            if (a.name === 'Indicadores da cidade') return 1;

            a = String(a.sort_field),
                b = String(b.sort_field);

            return a.localeCompare(b);
        });

        $.each(eixos_indicadores, function(eixo_index, eixo) {
            eixos_ordem.push(eixo.name);
        });

        var dimension_ant = 0;

        $.each(eixos_ordem, function(ix, eixo_index) {
            var eixo = eixos_indicadores[ix].resumo;

            if (eixos_indicadores[ix].dimension_id != dimension_ant) {
                if (eixos_indicadores[ix].dimension_id != 0 && (dimensions_GO[eixos_indicadores[ix].dimension_id])) {

                    if (dimensions_GO[eixos_indicadores[ix].dimension_id] != '__HIDE__') {
                        table_content += "<thead class='dimensions'><tr><th colspan='10'>$$dimension</th></thead>".render({
                            dimension: dimensions_GO[eixos_indicadores[ix].dimension_id]
                        });
                    }

                }
                dimension_ant = eixos_indicadores[ix].dimension_id;
            }
            table_content += "<thead class='eixos collapsed ::nodata::'><tr><th colspan='10'>$$eixo</th></thead>".render({
                eixo: eixo_index
            });
            var periods = eixo;
            $.each(periods, function(period_index, period) {
                var datas = periods[period_index].datas;
                var has_any_data = institute_info.hide_empty_indicators ? 0 : 1;
                if (datas.length > 0) {
                    table_content += "<thead class='datas'><tr><th></th><th>Autor</th>";
                    $.each(datas, function(index, value) {
                        table_content += "<th>$$data</th>".render({
                            data: (datas[index].nome) ? datas[index].nome : "Sem dados"
                        });
                    });
                    table_content += "<th></th></tr></thead>";
                    has_any_data++;
                } else {
                    table_content += '<thead class="datas ::nodata::"><tr><th></th><th></th><th colspan="10">Nenhum ano preenchido</th><th></th></tr></thead>';
                }

                table_content += "<tbody class='::nodata::'>";

                var indicadores = periods[period_index].indicadores;
                indicadores.sort(function(a, b) {
                    a = a.name;
                    b = b.name;

                    return a.localeCompare(b);
                });
                $.each(indicadores, function(i, item) {
                    var tr_class;
                    if (item.network_config.unfolded_in_home == 1) {
                        tr_class = "unfolded";
                    } else {
                        tr_class = "folded";
                    }
                    table_content += "<tr class='$$tr_class ::onehave::'><td class='nome'><a href='$$url' data-toggle='tooltip' data-placement='right' title data-original-title='$$explanation' class='bs-tooltip'>$$nome</a></td>".render({
                        tr_class: tr_class,
                        nome: item.name,
                        explanation: item.explanation,
                        url: (base_url) ? (base_url + "/" + item.name_url) : ((window.location.href.slice(-1) == "/") ? item.name_url : window.location.href + "/" + item.name_url)
                    });

                    if (item.source) {

                        var icone = [],
                            icone_title = [];

                        if (item.source == "[ICES]") {
                            icone.push("<img src='/static/images/icon_ICES.png'>");
                            icone_title.push("Indicador Metodologia Iniciativa Cidades Emergentes e Sustentáveis (ICES)");
                        }
                        if (item.source == "[PCS]" || new RegExp("pcs").test(item.source)) {
                            icone.push("<img src='/static/images/icon_PCS.png'>");
                            icone_title.push("Indicadores do Programa Cidades Sustentáveis");
                        }
                        if (new RegExp("urban").test(item.source)) {
                            icone.push("<img src='/static/images/icon_urban.png'>");
                            icone_title.push("Indicadores do Urban95");
                        }
                        if (new RegExp("progmetas").test(item.source)) {
                            icone.push("<img src='/static/images/icon_prog_metas.png'>");
                            icone_title.push("Indicadores do programa de metas");
                        } else if (item.source == "[REDE]") {
                            icone.push("<img src='/static/images/icon_Rede.png'>");
                            icone_title.push("Rede Social Brasileira por Cidades Justas e Sustentáveis");
                        }


                        if (icone.length > 0) {

                            var innerstr = '';
                            $.each(icone, function(idx) {
                                innerstr += "<div data-toggle='tooltip' data-placement='left' title data-original-title='$$title' class='bs-tooltip'>$$icone</div>".render({
                                    icone: icone[idx],
                                    title: icone_title[idx]
                                });

                            });


                            table_content += ("<td class='fonte forceinline'>" + innerstr + "</td>");


                        } else {
                            table_content += "<td class='fonte'></td>";
                        }
                    } else {
                        table_content += "<td class='fonte'></td>";
                    }
                    if (item.valores.length > 0) {

                        var have_data = institute_info.hide_empty_indicators ? 0 : 1;
                        for (j = 0; j < item.valores.length; j++) {
                            if (item.valores[j] == "-") {
                                table_content += "<td class='valor'>-</td>";
                            } else {
                                if (item.variable_type == 'str') {
                                    table_content += ('<td title="$$again" class="valor">' + (item.valores[j] ? '<i class="icon-ok"></i>' : '-') + '</td>').render({
                                        again: item.valores[j]
                                    });
                                    if (item.valores[j]) {
                                        have_data++;
                                    }
                                } else {
                                    var format_value = parseFloat(item.valores[j]);
                                    var format_string = "#,##0.##";
                                    if (format_value.toFixed(2) === 0) {
                                        format_string = "#,##0.###";
                                    }
                                    have_data++;
                                    table_content += "<td class='valor'>$$valor</td>".render({
                                        valor: $.formatNumberCustom(item.valores[j], {
                                            format: format_string,
                                            locale: "br"
                                        })
                                    });
                                }
                            }
                        }
                        table_content += "<td class='grafico'><a href='$$url'><canvas id='graph-$$id' width='40' height='20'></canvas></a></td>".render({
                            id: cont,
                            url: (base_url) ? (base_url + "/" + item.name_url) : ((window.location.href.slice(-1) == "/") ? item.name_url : window.location.href + "/" + item.name_url)
                        });

                        for (j = 0; j < item.valores.length; j++) {
                            if (item.valores[j] == "-") {
                                item.valores[j] = null;
                            }
                        }
                        graficos[cont] = item.valores;
                        cont++;
                        table_content = replaceAll('::onehave::', have_data ? '' : 'no-have', table_content);
                    } else {
                        table_content = replaceAll('::onehave::', institute_info.hide_empty_indicators ? 'no-have' : '', table_content);
                        table_content += "<td class='valor' colspan='5'>-</td>";
                    }
                });

                table_content = replaceAll('::nodata::', has_any_data ? '' : 'no-data', table_content);

                table_content += "</tbody>";
            });
        });

        table_content += "</table>";

        $("#cidades-indicadores .table").append(table_content);

        $(".bs-tooltip").tooltip();

        $("#cidades-indicadores thead.eixos").click(function() {
            $(this).toggleClass("collapsed");
            $(this).nextAll("thead.datas:first").toggle();
            var tbody = $(this).nextAll("tbody:first");
            $(tbody).find("tr.unfolded").removeClass("unfolded").addClass("folded");
            $(tbody).find("tr").toggle();
        });

        geraGraficos();
    }

    $('#indicadores-hide-toggle').click(function() {


        if (this.checked) {
            $('#cidades-indicadores .no-data').removeClass('no-data').addClass('no-data-show');
            $('#cidades-indicadores .no-have').removeClass('no-have').addClass('no-have-show');
        } else {

            $('#cidades-indicadores .no-data-show').removeClass('no-data-show').addClass('no-data');
            $('#cidades-indicadores .no-have-show').removeClass('no-have-show').addClass('no-have');
        }
        $('html,body').animate({
            scrollTop: 180
        }, 'fast');



    });

    var _change_colors = function(event) {

        $.each(this._data.list, function(a, b) {
            b.setOptions({
                strokeColor: '#EEE',
                strokeOpacity: 1,
                strokeWeight: 4
            });
        });
    };

    var _restore_change_colors = function(event) {

        $.each(this._data.list, function(a, b) {
            b.setOptions({
                strokeColor: '#333',
                strokeOpacity: 0.6,
                strokeWeight: 2
            });
        });
    };
    function geraGraficos() {


        for (i = 0; i < graficos.length; i++) {
            var ymin = 0;

            $.each(graficos[i], function(index, item) {
                if (index == 0) {
                    ymin = item;
                } else {
                    if (item && item < ymin) ymin = item;
                }
            });


            var line = new RGraph.Line('graph-' + i, graficos[i]);
            line.Set('chart.ylabels', false);
            line.Set('chart.noaxes', true);
            line.Set('chart.background.grid', false);
            line.Set('chart.hmargin', 0);
            line.Set('chart.gutter.left', 0);
            line.Set('chart.gutter.right', 0);
            line.Set('chart.gutter.top', 0);
            line.Set('chart.gutter.bottom', 0);
            line.Set('chart.colors', ['#b4b4b4']);

            if (ymin < 0) {
                line.Set('chart.xaxispos', 'center');
            }

            line.Draw();
        }
    }

    function formataMenuRegioes() {
        $("#regioes ul.regions li.header").each(function(index, item) {
            if ($(this).find("ul.subregions li.selected").length > 0) {
                $(this).find("ul.subregions").fadeIn("fast");
            }
        });
        $("#regioes ul.regions div.header").bind("click", function(e) {
            $(this).parent().find("ul.subregions").toggle("fast");
        });
    }
    if (ref == "cidade") {
        formataMenuRegioes();
        loadCidadeData();
    }
    if (ref == "region") {
        formataMenuRegioes();
        loadIndicadoresData();
        loadMapInfancia();
    }

    function _go_to_page (){
        window.location.href = this._data.url;
    }


    function loadMapInfancia(){

        var mapDefaultLocation = new google.maps.LatLng(-14.2350040, -51.9252800);
        var geocoder = new google.maps.Geocoder();

        var mapOptions = {
            center: mapDefaultLocation,
            zoom: zoom_padrao,
            mapTypeId: google.maps.MapTypeId.ROADMAP,
            draggable: false,
            scrollwheel: false,
            navigationControl: false,
            mapTypeControl: false,
            scaleControl: false,
            zoomControl: false,
            streetViewControl: false,
            fullscreenControl: false,
            styles: [{"elementType":"geometry","stylers":[{"color":"#ffffff"}]},{"elementType":"labels","stylers":[{"visibility":"off"}]},{"elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#ffffff"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"}]},{"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},{"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},{"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#ffffff"}]},{"featureType":"administrative.neighborhood","stylers":[{"visibility":"off"}]},{"featureType":"poi","stylers":[{"visibility":"off"}]},{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#eeeeee"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#ffffff"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#ffffff"}]},{"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#ffffff"}]},{"featureType":"road","stylers":[{"visibility":"off"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},{"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"featureType":"road.arterial","elementType":"labels.text.fill","stylers":[{"color":"#ffffff"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#ffffff"}]},{"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#ffffff"}]},{"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#ffffff"}]},{"featureType":"transit","stylers":[{"visibility":"off"}]},{"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#ffffff"}]},{"featureType":"transit.station","elementType":"geometry","stylers":[{"color":"#ffffff"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#ffffff"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#ffffff"}]}],
        };


        map = new google.maps.Map(document.getElementById("map_canvas"), mapOptions);
        if (!google.maps.Polygon.prototype.getBounds) {
            google.maps.Polygon.prototype.getBounds = function(latLng) {

                var bounds = new google.maps.LatLngBounds();
                var paths = this.getPaths();
                var path;

                for (var p = 0; p < paths.getLength(); p++) {
                    path = paths.getAt(p);
                    for (var i = 0; i < path.getLength(); i++) {
                        bounds.extend(path.getAt(i));
                    }
                }

                return bounds;
            };
        }

        var the_regions = $.parseJSON( $('#map_canvas').attr('data-regions'));

        google.maps.event.addListenerOnce(map, 'idle', function() {

                var full_polys = Array();

                $.each(the_regions, function(i, region) {

                    var elm = region;
                    elm.list = Array();

                    $.each([region.p], function(aa, elm2) {

                        if (elm2 === null) {
                            return true;
                        }

                        var zoo = {
                            coords: google.maps.geometry.encoding.decodePath(elm2)
                        };

                        if (zoo.coords == null || zoo.coords == undefined) {
                            return true;
                        }

                        var thecolor = '#F0F';//_get_color(region_id);

                        zoo.polygon = new google.maps.Polygon({
                            paths: zoo.coords,
                            strokeColor: '#333',
                            strokeOpacity: 0.6,
                            strokeWeight: 2,
                            fillColor: thecolor,
                            fillOpacity: 0.8
                        });



                        elm.list.push(zoo.polygon);

                        zoo.polygon._data = elm;
                        zoo.polygon._data.map = map;

                        zoo.polygon.setMap(map);
                        google.maps.event.addListener(zoo.polygon, 'click', _go_to_page);

                        google.maps.event.addListener(zoo.polygon, 'mouseover', _change_colors);
                        google.maps.event.addListener(zoo.polygon, 'mouseout', _restore_change_colors);

                        full_polys.push(zoo)

                        return true;
                    });
                });

                var super_bound = null;
                $.each(full_polys, function(a, elm) {

                    if (super_bound === null) {
                        super_bound = elm.polygon.getBounds();
                        return true;
                    }

                    super_bound = super_bound.union(elm.polygon.getBounds());
                    return true;
                });

                if (!(super_bound === null)) {
                    map.fitBounds(super_bound);
                }

            });


    }


});