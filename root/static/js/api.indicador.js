var indicador_data;
var historico_data;
var variaveis_data = [];
var data_vvariables = [];
var cidade_uri;
var cidade_data;
var $dados;

$(document).ready(function () {

    var source_values = [];
    var goal_values;
    var observations_values;

    var param = typeof regionID == "undefined" ? '' : '?region_id=' + regionID;
    $.loadCidadeDataIndicador = function () {
        $.ajax({
            type: 'GET',
            dataType: 'json',
            url: (api_path + '/api/public/user/$$id' + param).render({
                id: userID
            }),
            success: function (data, textStatus, jqXHR) {
                cidade_data = data;
                loadIndicadorData();
            },
            error: function (data) {
                console.log("erro ao carregar informações da cidade");
            }
        });
    };

    function loadIndicadorData() {

        $.ajax({
            type: 'GET',
            dataType: 'json',
            url: (api_path + '/api/public/user/$$id/indicator/$$indicator_id' + param).render({
                id: userID,
                indicator_id: indicadorID
            }),
            success: function (data, textStatus, jqXHR) {
                indicador_data = data;
                indicadorDATA = data;
                loadVariaveisData();
            },
            error: function (data) {
                console.log("erro ao carregar informações do indicador");
            }
        });
    }

    function loadVariaveisData() {
        $.ajax({
            type: 'GET',
            dataType: 'json',
            url: api_path + '/api/public/user/variable',
            success: function (data, textStatus, jqXHR) {
                $.each(data.variables, function (index, value) {
                    variaveis_data.push({
                        "id": data.variables[index].id,
                        "name": data.variables[index].name
                    });
                });
                loadVVariaveisData();
            },
            error: function (data) {
                console.log("erro ao carregar informações do indicador");
            }
        });
    }

    function loadVVariaveisData() {

        data_vvariables = [];
        $.ajax({
            type: 'GET',
            dataType: 'json',
            url: api_path + '/api/public/user/indicator/variable',
            success: function (data, textStatus, jqXHR) {
                $.each(data.variables, function (index, value) {
                    data_vvariables.push({
                        "id": data.variables[index].id,
                        "name": data.variables[index].name
                    });
                });
                showIndicadorData();
                loadHistoricoData();
            }
        });

    }

    function formataFormula(formula, variables, vvariables) {
        var operators_caption = {
            "+": "+",
            "-": "-",
            "(": "(",
            ")": ")",
            "/": "÷",
            "*": "×",
            "CONCATENAR": ""
        };

        var new_formula = formula, is_string = /CONCATENAR/i.test(formula);


        variables.sort(function (a, b) {
            return b.id - a.id;
        });

        $.each(operators_caption, function (index, value) {
            new_formula = new_formula.replace(index, " " + value + " ");
        });

        $.each(variables, function (index, value) {
            var pattern = "\\$" + variables[index].id;
            var re = new RegExp(pattern, "g");
            new_formula = new_formula.replace(re, variables[index].name) + ( is_string? "\n" : " ");
        });


        if (vvariables) {
            vvariables.sort(function (a, b) {
                return b.id - a.id;
            });
            $.each(vvariables, function (index, value) {
                var pattern = "\\#" + vvariables[index].id;
                var re = new RegExp(pattern, "g");
                new_formula = new_formula.replace(re, vvariables[index].name) + ( is_string? "\n" : " ");
            });
        }

        new_formula = $.trim(new_formula);
        new_formula.replace(/ +/g, ' ');
        new_formula.replace(/ /g, '&nbsp;');

        return new_formula;
    }

    function showIndicadorData() {

        if (ref == 'indicador') {
            $("#indicador-dados .profile .title").html(indicador_data.name);
            $("h1").text(indicador_data.name + ' - ' + cidade_data.cidade.name + ', ' + cidade_data.cidade.uf);

            $("#indicador-dados .profile .explanation").html(indicador_data.explanation);
            $dados = $("#indicador-dados .profile .dados");
            $(".tabela", $dados).empty();
        } else {

            $(".indicador-dados .title").html(indicador_data.name);

            $(".indicador-dados .explanation").html(indicador_data.explanation);
            $dados = $(".indicador-dados .dados");
            $(".tabela", $dados).empty();

        }
        //if (indicador_data.formula.indexOf("CONCATENAR") < 0) {
            $(".tabela", $dados).append("<dt>Fórmula:</dt><dd class='white_space_pre_wrap'>"+formataFormula(indicador_data.formula, variaveis_data, data_vvariables)+"</dd>");
        //}
        var fonte_meta = "";
        if (indicador_data.goal_source) {
            fonte_meta = indicador_data.goal_source;
        }
        if (indicador_data.goal_explanation) {
            $(".tabela", $dados).append('<dt>$$aa:</dt><dd>$$dado<blockquote><small><cite title="$$bb: $$fonte_meta">$$fonte_meta</cite></small></blockquote></dd>'.render({
                dado: indicador_data.goal_explanation,
                fonte_meta: fonte_meta,
                aa: $('#ref_or_ods').text(),
                bb: $('#font_or_ods').text(),
            }));
        }
    }

    function loadHistoricoData() {
        $.ajax({
            type: 'GET',
            dataType: 'json',
            url: (api_path + '/api/public/user/$$id/indicator/$$indicator_id/variable/value' + (param ? param + '&indicator_value=1' : '?indicator_value=1' )).render({
                id: userID,
                indicator_id: indicadorID
            }),
            success: function (data, textStatus, jqXHR) {
                historico_data = data;
                $("#indicador-historico span.cidade").html(cidade_data.cidade.name + (cidade_data.region ? '/' + cidade_data.region.name : ''));
                $("#indicador-grafico span.cidade").html(cidade_data.cidade.name + (cidade_data.region ? '/' + cidade_data.region.name : ''));
                $("#indicador-grafico .title a.link").attr("href", "/" + indicador_data.name_url + "/?view=graph&graphs=" + userID);

                $('#indicador-historico label').remove();
                if (indicador_data.indicator_type == 'varied') {
                    var html_combo = '<label>Faixa: <select id="variation" class="span6" name="variation">';

                    $.each(indicador_data.variations, function (i, v) {
                        html_combo = html_combo + '<option value="$$name">$$name</option>'.render({
                            name: v.name
                        });
                    });
                    html_combo = html_combo + '</select></label>';
                    $('#indicador-historico').prepend($(html_combo).change(showHistoricoData));
                }


                showHistoricoData();



                if ((goal_values) && $.trim(goal_values) !== "") {
                    if (goal_values.toLowerCase().indexOf("fonte:") > 0) {
                        goal_values = goal_values.replace("fonte:", "Fonte:");
                        goal_values = goal_values.replace("Fonte:", '<blockquote><small><cite title="Fonte da meta">') + "</cite></small></blockquote>";
                    }
                    $(".tabela", $dados).append("<dt>$$aa:</dt><dd>$$dado</dd>".render({
                        dado: goal_values,
                        aa: $('#ref_or_ods').text()
                    }));
                }

                if (source_values.length > 0) {

                    var source_values_unique = [];
                    $.each(source_values, function (i, el) {
                        if ($.inArray(el, source_values_unique) === -1) {
                            source_values_unique.push(el);
                        }
                    });
                    $(".tabela", $dados).append("<dt>Fontes do Indicador:</dt><dd><ul><li>$$dado</li></ul></dd>".render({
                        dado: source_values_unique.join("__885__")
                    }).replace(/__885__/g, '</li><li>') ) ;
                }

                if ((observations_values) && $.trim(observations_values) !== "") {
                    var observations_values_unique = [];
                    $.each(observations_values, function (i, el) {
                        if ($.inArray(el, observations_values_unique) === -1) {
                            observations_values_unique.push(el);
                        }
                    });

                    $(".tabela", $dados).append("<dt>Observações:</dt><dd><ul><li>$$dado</li></ul></dd>".render({
                        dado: observations_values_unique.join("__885__")
                    }).replace(/__885__/g, '</li><li>') );
                }

                if (indicador_data.user_indicator_config && indicador_data.user_indicator_config.technical_information) {
                    $(".tabela", $dados).append("<dt>Informações Técnicas:</dt><dd>$$dado</dd>".render({
                        dado: indicador_data.user_indicator_config.technical_information
                    }).replace(/\n/g, '<br/>') );
                }

                $(".tabela", $dados).append( $('#justifications').html() );

                if (!(indicador_data.variable_type == 'str')) {

                    showGrafico();
                } else {
                    $('#indicador-grafico').hide();
                }

                $(".indicators").removeClass("meloading");

            },
            error: function (data) {
                console.log("erro ao carregar série histórica");
                $(".indicators").removeClass("meloading");
            }
        });
    }

    function numKeys(obj) {
        var count = 0;
        for (var prop in obj) {
            count++;
        }
        return count;
    }

    function showHistoricoData() {


        if (historico_data.rows) {
            var history_table = "<table class='history table table-striped table-condensed'><thead><tr><th>Período</th>";

            var headers = []; //corrige ordem do header
            $.each(historico_data.header, function (titulo, index) {
                headers[index] = titulo;
            });

            $.each(headers, function (index, value) {
                history_table += "<th class='variavel'>$$variavel</th>".render({
                    variavel: value
                });
            });
            var hvariado = Array();
            if (historico_data.variables_variations) {

                $.each(historico_data.variables_variations, function (index, tv) {
                    history_table += "<th class='variavel'>$$variavel</th>".render({
                        variavel: tv.name
                    });
                    hvariado.push(tv.id);
                });
            }


            if (!(indicador_data.variable_type == 'str')) {
                history_table += "<th class='formula_valor'>Valor da Fórmula</th>";
            }

            history_table += "</tr><tbody>";

            dadosGrafico = {
                "dados": [],
                "labels": []
            };


            observations_values = [];
            source_values = [];
            goal_values = '';
            var valores = [];
            var grafico_variado;


            $.each(historico_data.rows, function (index, value) {

                history_table += "<tr><td class='periodo'>$$periodo</td>".render({
                    periodo: convertDateToPeriod(historico_data.rows[index].valid_from, indicador_data.period)
                });
                dadosGrafico.labels.push(convertDateToPeriod(historico_data.rows[index].valid_from, indicador_data.period));

                var cont = 0,
                    num_var = numKeys(historico_data.header);
                $.each(historico_data.rows[index].valores, function (index2, value2) {
                    var valor_linha = historico_data.rows[index].valores[index2];
                    cont++;
                    if (valor_linha !== null) {
                        if (indicador_data.variable_type == 'str') {
                            history_table += "<td class='valor'>$$valor</td>".render({
                                valor: valor_linha.value == null ? '-' : valor_linha.value
                            });
                        } else {
                            var format_value = parseFloat(valor_linha);
                            var format_string = "#,##0.##";
                            if (format_value.toFixed(2) === 0) {
                                format_string = "#,##0.###";
                            }
                            history_table += "<td class='valor'>$$valor</td>".render({
                                valor: $.formatNumberCustom(valor_linha.value, {
                                    format: format_string,
                                    locale: "br"
                                }),
                                data: convertDate(valor_linha.value_of_date, "T")
                            });

                        }

                        if (valor_linha.source) {
                            source_values.push(valor_linha.source);
                        }

                        if (valor_linha.observations) {
                            observations_values.push(valor_linha.observations);
                        }

                    } else {
                        history_table += "<td class='valor'>-</td>";
                    }
                });

                for (i = cont; i < num_var; i++) {
                    history_table += "<td class='valor'>-</td>";
                }

                if (!(indicador_data.variable_type == 'str')) {

                    if (indicador_data.indicator_type == 'varied') {
                        if (grafico_variado == undefined) {
                            grafico_variado = {};
                        }



                        var valor = '';
                        var valoresxx;

                        $.each(historico_data.rows[index].variations, function (i, vv) {
                            if (grafico_variado[vv.name] == undefined) {
                                grafico_variado[vv.name] = [];
                            }
                            if (vv.value == '-') {
                                grafico_variado[vv.name][index] = null;
                            } else {
                                grafico_variado[vv.name][index] = vv.value;
                            }

                            if (vv.name == $('#variation').val()) {
                                valor = vv.value;
                                valoresxx = vv.variations_values;
                            }
                        });


                        if (hvariado.length) {

                            $.each(hvariado, function (index, id) {

                                if (valoresxx == undefined || valoresxx[id] == undefined || valoresxx[id] === '' || valoresxx[id] == '-') {
                                    history_table += "<td class='formula_valor'>-</td>";
                                } else {
                                    var format_value = parseFloat(valoresxx[id]['value']);
                                    var format_string = "#,##0.##";
                                    if (format_value.toFixed(2) === 0) {
                                        format_string = "#,##0.###";
                                    }
                                    history_table += "<td class='formula_valor'>$$valor</td>".render({
                                        valor: $.formatNumberCustom(format_value, {
                                            format: format_string,
                                            locale: "br"
                                        })
                                    });

                                }
                            });

                        }
                        var format_value = parseFloat(valor);
                        var format_string = "#,##0.##";
                        if (format_value.toFixed(2) === 0) {
                            format_string = "#,##0.###";
                        }

                        history_table += "<td class='formula_valor'>$$valor</td>".render({
                            valor: $.formatNumberCustom(valor, {
                                format: format_string,
                                locale: "br"
                            })
                        });

                    } else {

                        if (historico_data.rows[index].formula_value != null && historico_data.rows[index].formula_value != "-") {
                            var format_value = parseFloat(historico_data.rows[index].formula_value);
                            var format_string = "#,##0.####";
                            if (format_value.toFixed(2) === 0) {
                                format_string = "#,##0.###";
                            }
                            history_table += "<td class='formula_valor'>$$formula_valor</td>".render({
                                formula_valor: $.formatNumberCustom(historico_data.rows[index].formula_value, {
                                    format: format_string,
                                    locale: "br"
                                })
                            });
                        } else {
                            history_table += "<td class='formula_valor'>-</td>";
                        }
                    }
                }
                history_table += "</tr>";
                if (historico_data.rows[index].goal) {
                    goal_values = historico_data.rows[index].goal;
                }

                if (historico_data.rows[index].formula_value != "-" && historico_data.rows[index].formula_value != "" && historico_data.rows[index].formula_value != null) {
                    valores.push(parseFloat(historico_data.rows[index].formula_value).toFixed(3));
                } else {
                    valores.push(null);
                }

            });
            history_table += "</tbody></table>";

            if (indicador_data.indicator_type == 'varied') {
                history_table = history_table + '<div class="title">' + indicador_data.variety_name + '</div>' + "<table class='history table table-striped table-condensed'><thead><tr><th>Período</th><th>Soma das faixas</th>";

                history_table += "</tr><tbody>";
                $.each(historico_data.rows, function (index, value) {

                    history_table += "<tr><td class='periodo'>$$periodo</td>".render({
                        periodo: convertDateToPeriod(historico_data.rows[index].valid_from, indicador_data.period)
                    });


                    if (historico_data.rows[index].formula_value != null && historico_data.rows[index].formula_value != "-") {
                        history_table += "<td class='formula_valor'>$$formula_valor</td>".render({
                            formula_valor: $.formatNumberCustom(historico_data.rows[index].formula_value, {
                                format: "#,##0.###",
                                locale: "br"
                            })
                        });
                    } else {
                        history_table += "<td class='formula_valor'>-</td>";
                    }

                    history_table += "</tr>";
                });
                history_table += "</tbody></table>";
            }

            if (typeof grafico_variado == "undefined") {
                var nome_grafico = typeof regionID == "undefined" ? cidade_data.cidade.name : cidade_data.region.name;

                dadosGrafico.dados.push({
                    id: userID,
                    nome: nome_grafico,
                    valores: valores,
                    show: true
                });
            } else {

                var em_ordem = [];

                $.each(grafico_variado, function (a, b) {
                    em_ordem.push(a);
                });
                em_ordem.sort();

                $.each(em_ordem, function (index, chave) {

                    dadosGrafico.dados.push({
                        id: userID,
                        nome: chave,
                        valores: grafico_variado[chave],
                        show: true
                    });

                });

            }

        } else {
            history_table = "<table class='history'><thead><tr><th>nenhum registro encontrado</th></tr></thead></table>";
            dadosGrafico = {
                dados: []
            };
        }
        $("#indicador-historico .table .content-fill").html(history_table);

    }


    function showGrafico() {
        _resize_canvas();
        if (dadosGrafico.dados.length > 0) {
            $("#indicador-grafico").show();
            $.carregaGrafico("main-graph");
        } else {
            $("#indicador-grafico").hide();

        }
    }

    if (ref == "indicador" || ref == "region_indicator") {
        $(".indicators").addClass("meloading");
        $.loadCidadeDataIndicador();
    }

});
