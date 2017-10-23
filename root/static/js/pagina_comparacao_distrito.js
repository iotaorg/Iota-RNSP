var pcd = function() {
    function encodeHTML(s) {
        if (typeof s == 'string') {
            return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');
        } else {
            return s;
        }
    }

    var

        $submit = $('button[type=submit]:first'),
        $cidade = $('select[name="cidade"]:first'),
        $period = $('select[name="valid_from"]:first'),
        $indi = $('select[data-name="indicador"]:first'),
        $form = $('form:first'),
        $indicadors_input = $('input[name="selected_indicators"]:first'),
        $btn_add = $('.button-add-indicator:first'),

        $table_container = $('#table-container'),
        container_original_html = $table_container.html(),
        table_template = $('.table-selected-indicators:first').clone().wrap('<div></div>').parent().html(),
        indicator_template = $indi.html(),

        max_selected_indicators = $indi.attr('data-max-selected-indicators') * 1,
        selected_indicators_count = $indicadors_input.val().length >= 1 ? $indicadors_input.val().split(',').length : 0,

        _init = function() {

            $btn_add.click(_onclick_btn_add);

            $table_container.on('click', '.xbtn .button-del', _onclick_btn_remove);


            $('.button-change-params:first').click(function() {
                $('.changeparam').removeClass('hide');
                $('.comparacao-results').addClass('hide');
            });

            $cidade.change(_recalc_submit_prop);
            $indi.change(_recalc_btn_add_prop);

            $period.change(_refresh_indicators);
            $cidade.change(_refresh_indicators);

            $form.submit(function() {
                $submit.prop('disabled', true);
                return true;
            });

            // se só tem uma cidade, escolhe sozinho ela
            if ($cidade[0].length == 2) {
                $cidade[0].selectedIndex = 1;
            }

            // força um desenho da tabela
            _indicators_changed();

            _refresh_indicators();
        },
        _recalc_btn_add_prop = function() {
            // botao só ativo se tiver valor no indicador e quatidade de indicadores nao passou do limite
            var xbool = $indi.val() != '' && selected_indicators_count < max_selected_indicators;
            $btn_add.prop('disabled', !xbool);
        },
        _refresh_indicators = function() {
            var city_id = $cidade.val(),
                period = $period.val();

            if (!city_id) return;
            if (!period) return;

            $.get("/api/public/indicator-availability-city-year", {
                city_id: city_id,
                depth_level: 3,
                periods: period
            }, function(o) {

                var options = indicator_template;

                $.each(o.indicators, function(idx, ind) {
                    options = options + '<option value="' + ind.id + '">' + encodeHTML(ind.name) + '</option>';

                });

                $indi.html(options);

            }, 'json').fail(function(e) {
                $table_container.text("ERRO: " + e.responseText);
            });


        },
        _onclick_btn_add = function() {


            var indicator = $indi.val(),
                current_indicators_str = ',' + $indicadors_input.val() + ',';

            if (current_indicators_str.indexOf(',' + indicator + ',') == -1) {

                $indicadors_input.val($indicadors_input.val().length == 0 ? indicator : $indicadors_input.val() + ',' + indicator);

                selected_indicators_count++;
                $indi[0].selectedIndex = 0;
                $indi.change();

                _indicators_changed();
            } else {
                alert($indi.attr('data-already-exists'))
            }


        },
        _onclick_btn_remove = function(e) {

            var $tr = $(this).parents('tr:first'),
                indicator = $tr.attr('data-id');

            var current_indicators_str = ',' + $indicadors_input.val() + ',';

            if (current_indicators_str.indexOf(',' + indicator + ',') != -1) {

                var new_val = [];
                $.each($indicadors_input.val().split(','), function(i, v) {
                    if (v != indicator) {
                        new_val.push(v);
                    }
                });


                $indicadors_input.val(new_val.join(','));

                selected_indicators_count--;

                _recalc_btn_add_prop();

                _indicators_changed();

            }


        },
        _recalc_submit_prop = function() {

            $submit.prop('disabled', selected_indicators_count == 0 || $cidade.val() == '');
        },
        _indicators_changed = function() {

            _recalc_submit_prop();

            if (selected_indicators_count > 0) {

                var $new_table = $(table_template.replace('__NUM__', selected_indicators_count)),
                    row_base = $new_table.find('tbody>tr');
                $new_table.find('tbody>tr').remove();
                $new_table.removeClass('hide');

                if (selected_indicators_count == max_selected_indicators)
                    $new_table.addClass('is-full');

                $.each($indicadors_input.val().split(','), function(i, v) {

                    var name = $indi.find('option[value=' + v + ']:first').text(),
                        $row = row_base.clone(false);

                    $row.find('td.indname').text(name);
                    $row.attr('data-id', v);

                    $new_table.find('tbody').append($row);

                });

                $table_container.html($new_table);

            } else {
                $table_container.html(container_original_html);

            }

        };
    return {
        run: _init
    };
}();

var map;


var pdc_results = function() {
    var _change_colors = function(event) {

        $.each(this._data.list, function(a, b) {
            b.setOptions({
                strokeColor: '#15d400',
                strokeOpacity: 0.8,
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

    var infowindow;
    var _show_info_name = function(event) {

        var region_id = this._data.region_id;
        var yregions = response.values[active_variation][region_id];

        if (yregions == undefined) return;

        var $new_table = $(infopop_template.replace('__NAME__', response.regions[region_id].name));
        $new_table.removeClass('hide');

        var indicators_in_order = response.indicators_in_order;

        $.each(indicators_in_order, function(idx, indicator_id) {
            $new_table.find('thead>tr').append(_th('', response.indicators_apels[indicator_id], response.indicators[indicator_id].name))
        })

        var tbody = '';
        $.each(yregions, function(year, indicators) {
            var row = '<tr>';

            row = _td(row, year, '', 'minwidth');

            $.each(indicators_in_order, function(idx, indicator_id) {


                if (indicators[indicator_id] == undefined) {

                    row = _td(row, '-', '', 'tcenter');

                } else {

                    row = _td(row, indicators[indicator_id].rnum, indicators[indicator_id].num, 'tcenter');

                }

            });

            tbody += row + '</tr>';

        });
        $new_table.find('tbody').append(tbody);

        infowindow.setContent($new_table[0]);
        infowindow.setPosition(event.latLng);

        infowindow.open(this._data.map);
    };

    var
        $table_container = $('div.results-container:first'),
        response,
        active_variation,
        table_template,
        infopop_template,
        map_template,
        indicators_apels,

        _init = function() {

            var params = $table_container.attr('data-search-params');
            if (!params) return;
            params = jQuery.parseJSON(params);

            table_template = $('.table-results-indicators:first').clone().wrap('<div></div>').parent().html();
            map_template = $('#map_container').clone().wrap('<div></div>').parent().html();
            infopop_template = $('.infopop:first').clone().wrap('<div></div>').parent().html();

            $.get("/api/public/compare-by-region", params, _on_results, 'json').fail(function(e) {
                $table_container.text("ERRO: " + e.responseText);
            });

        },
        _on_results = function(data) {

            if (!data.values || !data.regions || !data.indicators) {
                $table_container.text("Erro com o resultado");
                return;
            }

            response = data;

            active_variation = response.variations['0'];

            if (!(active_variation == undefined)) {
                redraw_results();
            } else {

                $table_container.text("Nenhum dado encontrado....");
            }

        },
        _td = function(e, str, title, cx) {
            return e + '<td' + (title ? ' title="' + title.replace('"', "'") + '"' : '') + (cx ? ' class="' + cx + '"' : '') + '>' + str + '</td>'
        },
        _th = function(e, str, title, cx) {
            return e + '<th' + (title ? ' title="' + title.replace('"', "'") + '"' : '') + (cx ? ' class="' + cx + '"' : '') + '>' + str + '</th>'
        },
        _get_color = function(region_id) {

            var color = '#333';

            var yregions = response.values[active_variation][region_id];

            if (yregions == undefined) return color;

            var good_count = 0,
                bad_count = 0,
                total = 0;

            $.each(yregions, function(year, indicators) {
                $.each(indicators, function(id_id, vv) {
                    total++;
                    if (vv.i == 0) good_count++;
                    if (vv.i > 0) bad_count++;
                });
            });

            if (good_count == total) {
                color = '#d7e7ff';
            } else if (bad_count == total) {
                color = '#cc0314';
            } else {
                color = '#cca203'
            };

            return color;

        },
        _load_map = function(map_elm) {

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
            if (!infowindow) {
                infowindow = new google.maps.InfoWindow();
            }

            var $elm = $(map_elm);

            var mapDefaultLocation = new google.maps.LatLng(-23.5486, -46.6392);

            var mapOptions = {
                center: mapDefaultLocation,
                zoom: 10,
                mapTypeId: google.maps.MapTypeId.ROADMAP
            };
            map = new google.maps.Map($elm[0], mapOptions);


            google.maps.event.addListenerOnce(map, 'idle', function() {


                var full_polys = Array();

                $.each(response.regions, function(region_id, region) {

                    var elm = region;
                    elm.list = Array();
                    elm.region_id = region_id;

                    $.each([region.polygon_path], function(aa, elm2) {

                        if (elm2 === null) {
                            return true;
                        }

                        var zoo = {
                            coords: google.maps.geometry.encoding.decodePath(elm2)
                        };

                        if (zoo.coords == null || zoo.coords == undefined) {
                            return true;
                        }

                        var thecolor = _get_color(region_id);

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
                        google.maps.event.addListener(zoo.polygon, 'click', _show_info_name);
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


        },
        redraw_results = function() {

            var $new_div = $('<div></div>'),
                $new_map = $(map_template.replace('REPLACE_MAP_ID', 'mapa'));

            $new_map.removeClass('hide');

            $new_div.append($new_map);

            $new_table = $(table_template);
            $new_table.removeClass('hide');

            var indicators_in_order = response.indicators_in_order;
            var regions_in_order = response.regions_in_order;

            $.each(indicators_in_order, function(idx, indicator_id) {
                $new_table.find('thead>tr').append(_th('', response.indicators[indicator_id].name, response.indicators_apels[indicator_id], ))
            })


            var tbody = '';

            var vregions = response.values[active_variation];

            $.each(regions_in_order, function(idx, region_id) {

                var years = vregions[region_id];

                if (!years)
                    return true;

                $.each(years, function(year, indicators) {


                    var row = '<tr>';
                    row = _td(row, response.regions[region_id].name, '', 'tright minwidth2');
                    row = _td(row, year, '', 'minwidth');


                    $.each(indicators_in_order, function(idx, indicator_id) {


                        if (indicators[indicator_id] == undefined) {

                            row = _td(row, '-', '', 'tcenter');

                        } else {

                            row = _td(row, indicators[indicator_id].rnum, indicators[indicator_id].num, 'tcenter');

                        }

                    });

                    tbody += row + '</tr>';

                });

            });

            $new_table.find('tbody').append(tbody);

            $new_div.append($new_table);

            $table_container.html($new_div);



            if (map) {
                _load_map($new_map.find('#mapa'))

            } else {

                google.maps.event.addDomListener(window, 'load', function() {
                    _load_map($new_map.find('#mapa'))
                });
            }



        };
    return {
        run: _init
    };
}();


$(function() {
    pcd.run();
    pdc_results.run();
});