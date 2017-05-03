var api_path = "";
var institute_info;
var infowindow;
var _show_info_name = function (event) {
    infowindow.setContent(this._data.name);
    infowindow.setPosition(event.latLng);

    infowindow.open(this._data.map);
};

var _change_colors = function (event) {

    $.each(this._data.list, function (a, b) {
        b.setOptions({
            strokeColor: '#15d400',
            strokeOpacity: 0.8,
            strokeWeight: 4
        });
    });
};
var _restore_change_colors = function (event) {

    $.each(this._data.list, function (a, b) {
        b.setOptions({
            strokeColor: '#333',
            strokeOpacity: 0.6,
            strokeWeight: 2
        });
    });
};

function debounce(fn, delay) {
    var timer = null;
    return function () {
        var context = this,
            args = arguments;
        clearTimeout(timer);
        timer = setTimeout(function () {
            fn.apply(context, args);
        }, delay);
    };
}
(function ($) {
    $.fn.disableSelection = function () {
        return this.attr('unselectable', 'on')
            .css('user-select', 'none')
            .on('selectstart', false);
    };
})(jQuery);

//var api_path = "http://rnsp.aware.com.br";
var _last_width = 0;

function encodeHTML(s) {
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');
}

if (!String.prototype.render) {
    String.prototype.render = function (args) {
        var copy = this + '';
        for (var i in args) {
            copy = copy.replace(RegExp('\\$\\$' + i, 'g'), encodeHTML(args[i]) );
        }
        return copy;
    };
}

if (!Array.prototype.indexOf) {
    Array.prototype.indexOf = function (elt /*, from*/ ) {
        var len = this.length >>> 0;

        var from = Number(arguments[1]) || 0;
        from = (from < 0) ? Math.ceil(from) : Math.floor(from);
        if (from < 0) {
            from += len;
        }
        for (; from < len; from++) {
            if (from in this &&
                this[from] === elt) {
                return from;
            }
        }
        return -1;
    };
}

var _on_func = function (e) {
    var $elm = $(e.target);
    if ($elm.hasClass('mapa')) {

        var $place = $($elm.attr('href'));
        var idx = $place.find('[map_index]:first').attr('map_index');
        var map = map_references[idx];

        map.fitBounds(map_references_bound[idx]);
    }
};
$('a[data-toggle="tab"]').on('shown', _on_func);

if ('a,,b'.split(',').length < 3) {
    var nativeSplit = nativeSplit || String.prototype.split;
    String.prototype.split = function (s /* separator */ , limit) {
        // If separator is not a regex, use the native split method
        if (!(s instanceof RegExp)) {
            return nativeSplit.apply(this, arguments);
        }

        /* Behavior for limit: If it's...
         - Undefined: No limit
         - NaN or zero: Return an empty array
         - A positive number: Use limit after dropping any decimal
         - A negative number: No limit
         - Other: Type-convert, then use the above rules */
        if (limit === undefined || +limit < 0) {
            limit = false;
        } else {
            limit = Math.floor(+limit);
            if (!limit) {
                return [];
            }
        }

        var flags = (s.global ? "g" : "") + (s.ignoreCase ? "i" : "") + (s.multiline ? "m" : ""),
            s2 = new RegExp("^" + s.source + "$", flags),
            output = [],
            lastLastIndex = 0,
            i = 0,
            match;

        if (!s.global) {
            s = new RegExp(s.source, "g" + flags);
        }

        while ((!limit || i++ <= limit) && (match = s.exec(this))) {
            var zeroLengthMatch = !match[0].length;

            // Fix IE's infinite-loop-resistant but incorrect lastIndex
            if (zeroLengthMatch && s.lastIndex > match.index) {
                s.lastIndex = match.index; // The same as s.lastIndex--
            }

            if (s.lastIndex > lastLastIndex) {
                // Fix browsers whose exec methods don't consistently return undefined for non-participating capturing groups
                if (match.length > 1) {
                    match[0].replace(s2, function () {
                        for (var j = 1; j < arguments.length - 2; j++) {
                            if (arguments[j] === undefined) {
                                match[j] = undefined;
                            }
                        }
                    });
                }

                output = output.concat(this.slice(lastLastIndex, match.index), (match.index === this.length ? [] : match.slice(1)));
                lastLastIndex = s.lastIndex;
            }

            if (zeroLengthMatch) {
                s.lastIndex++;
            }
        }

        return (lastLastIndex === this.length) ?
            (s.test("") ? output : output.concat("")) :
            (limit ? output : output.concat(this.slice(lastLastIndex)));
    };
}

$.xhrPool = [];
$.xhrPool.abortAll = function () {
    $(this).each(function (idx, jqXHR) {
        jqXHR.abort();
    });
    $.xhrPool.length = 0;
};

$.ajaxSetup({
    beforeSend: function (jqXHR) {
        $.xhrPool.push(jqXHR);
        NProgress.start();
    },
    complete: function (jqXHR) {
        var index = $.xhrPool.indexOf(jqXHR);
        if (index > -1) {
            $.xhrPool.splice(index, 1);
        }
        if ($.xhrPool.length === 0) {

            NProgress.done();

        }
    }
});

var findInJson = function (obj, key, value) {
    var found = false;
    var key_found = "";
    $.each(obj, function (key1, value1) {
        $.each(obj[key1], function (key2, value2) {
            if (key2 == key) {
                if (value2 == value) {
                    found = true;
                    key_found = key1;
                    return false;
                }
            }
        });
    });
    var retorno = {
        "found": found,
        "key": key_found
    };
    return retorno;
};

var convertDate = function (date, splitter) {
    var date_tmp = date.split(splitter);
    date = date_tmp[0];
    var time = date_tmp[1];

    var date_split = date.split("-");

    return date_split[2] + "/" + date_split[1] + "/" + date_split[0];
};

var convertDateToPeriod = function (date, period) {
    if (period == "yearly") {
        return date.split("-")[0];
    } else if (period == "monthly") {
        return date.split("-")[1] + "/" + date.split("-")[0];
    }
};

var findInArray = function (obj, value) {
    if (value === "") {
        return true;
    }
    var retorno = false;
    for (a = 0; a < obj.length; a++) {
        if (obj[a] == value) {
            retorno = true;
        }
    }
    return retorno;
};


var estados_sg = [];

estados_sg.push(["Acre", "AC"]);
estados_sg.push(["Alagoas", "AL"]);
estados_sg.push(["Amapá", "AP"]);
estados_sg.push(["Amazonas", "AM"]);
estados_sg.push(["Bahia", "BA"]);
estados_sg.push(["Ceará", "CE"]);
estados_sg.push(["Distrito Federal", "DF"]);
estados_sg.push(["Espírito Santo", "ES"]);
estados_sg.push(["Goiás", "GO"]);
estados_sg.push(["Maranhão", "MA"]);
estados_sg.push(["Mato Grosso", "MT"]);
estados_sg.push(["Mato Grosso do Sul", "MS"]);
estados_sg.push(["Minas Gerais", "MG"]);
estados_sg.push(["Pará", "PA"]);
estados_sg.push(["Paraíba", "PB"]);
estados_sg.push(["Paraná", "PR"]);
estados_sg.push(["Pernambuco", "PE"]);
estados_sg.push(["Piauí", "PI"]);
estados_sg.push(["Rio de Janeiro", "RJ"]);
estados_sg.push(["Rio Grande do Norte", "RN"]);
estados_sg.push(["Rio Grande do Sul", "RS"]);
estados_sg.push(["Rondônia", "RO"]);
estados_sg.push(["Roraima", "RR"]);
estados_sg.push(["Santa Catarina", "SC"]);
estados_sg.push(["São Paulo", "SP"]);
estados_sg.push(["Sergipe", "SE"]);
estados_sg.push(["Tocantins", "TO"]);

var paises = [];

paises["br"] = "Brazil";


var normalize = function (term) {
    return term.latinize().toLowerCase();
};

$.extend({
    isNumber: function (o) {
        return !isNaN(o - 0) && o !== null && o !== "" && o !== false;
    },
    formatNumberCustom: function (number, mask) {

        var ret = 'ERR';
        if (number == null) {
            ret = '-';
        } else if (number == "null") {
            ret = '-';
        } else if ($.isNumber(number)) {
            ret = $.formatNumber(number, mask);
        } else {
            if (number == '-') {
                ret = '-';
            } else {
                ret = '<abbr title="$$err">N/D</abbr>'.render({
                    err: number
                });
            }
        }
        return ret == 'null' ? '-' : ret;
    },
    getUrlVars: function () {
        var vars = [],
            hash;
        var hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&');
        for (var i = 0; i < hashes.length; i++) {
            hash = hashes[i].split('=');
            vars.push(hash[0]);
            vars[hash[0]] = hash[1];
        }
        return vars;
    },
    getUrlVars_url: function (url) {
        var vars = {}, hash;

        if (url.indexOf('?') == -1) {
            return {};
        }

        var hashes = url.slice(url.indexOf('?') + 1).split('&');

        for (var i = 0; i < hashes.length; i++) {
            hash = hashes[i].split('=');
            //vars.push(hash[0]);
            vars[hash[0]] = hash[1];
        }
        return vars;
    },
    getPureUrl_url: function (url) {
        var vars = {}, hash;

        if (url.indexOf('?') == -1) {
            return url;
        }

        return url.substr(0, url.indexOf('?'));
    },
    getUrlVar: function (name) {
        return $.getUrlVars()[name];
    },
    getUrlParams: function () {
        var params = window.location.href.split("?");
        if (params.length > 1) {
            return "?" + params[1];
        } else {
            return "";
        }
    },
    removeItemInArray: function (obj, removeItem) {
        obj = $.grep(obj, function (value) {
            return value != removeItem;
        });
        return obj;
    },
    setUrl: function (args, data) {
        var url = window.location.href;

        url = $.update_url_params(url, args);

        if ((url == window.location.href) === false) {
            History.pushState(data, null, url);
        }
    },
    update_url_params: function (url, params) {

        var aaa = $.getUrlVars_url(url);
        $.each(params, function (a, b) {
            aaa[a] = b;
        });

        var encoded = $.param(aaa);
        return $.getPureUrl_url(url) + '?' + encoded;

    }
});

$(document).ready(function () {
    $.ajaxSetup({
        cache: false
    });
});

function updateURLParameter(url, param, paramVal) {
    var aaa = {};
    aaa[param] = paramVal;
    return $.update_url_params(url, aaa);
}

function _resize_canvas() {
    var $g = $('#main-graph'),
        w = $g.parent().width();
    if (w != _last_width) {
        $g.attr('width', w);
        $g.attr('height', w * 0.46);
        RGraph.Redraw();
    }
}

$(window).resize(function () {
    _resize_canvas();
});
var map_references = [];
var map_references_bound = [];
var map_index = 0;


if (!(typeof google == "undefined")) {

    var map_used_things = {};

    function initialize_maps() {
        if (typeof load_map == "undefined") {
            return false;
        }
        $.grep(load_map, function (xmap) {

            if (xmap.polygons.length === 0) {
                return true;
            }

            if (!$(xmap.map_elm)[0]) {
                return true;
            }

            var $elm = $(xmap.map_elm);
            $elm.parents('div.hideme:first').addClass('active');
            $elm.html('');
            var map = new google.maps.Map($(xmap.map_elm)[0], {
                mapTypeId: google.maps.MapTypeId.ROADMAP,
                zoomControl: true
            });
            map_references[map_index] = map;
            map.__index = map_index;
            $elm.attr('map_index', map_index);
            map_index++;


            if (!infowindow) {
                infowindow = new google.maps.InfoWindow();
            }

            var opacity = xmap.opacity ? xmap.opacity : 0.5;

            google.maps.event.addListenerOnce(map, 'idle', function () {

                $.each(xmap.polygons, function (a, elm) {

                    elm.list = Array();

                    $.each(elm.p, function (aa, elm2) {

                        if (elm2 === null) {
                            return true;
                        }


                        var zoo = {
                            coords: google.maps.geometry.encoding.decodePath(elm2)
                        };

                        zoo.polygon = new google.maps.Polygon({
                            paths: zoo.coords,
                            strokeColor: '#333',
                            strokeOpacity: 0.6,
                            strokeWeight: 2,
                            fillColor: elm.color,
                            fillOpacity: Math.min(opacity, 1)
                        });
                        elm.list.push(zoo.polygon);

                        zoo.polygon._data = elm;
                        zoo.polygon._data.map = map;

                        zoo.polygon.setMap(map);

                        google.maps.event.addListener(zoo.polygon, 'click', _show_info_name);
                        google.maps.event.addListener(zoo.polygon, 'mouseover', _change_colors);
                        google.maps.event.addListener(zoo.polygon, 'mouseout', _restore_change_colors);

                        if (typeof map_used_things[xmap.map_elm] == "undefined") {
                            map_used_things[xmap.map_elm] = [];
                        }

                        map_used_things[xmap.map_elm].push(zoo);

                        return true;
                    });


                });


                var super_bound = null;
                $.each(map_used_things[xmap.map_elm], function (a, elm) {

                    if (super_bound === null) {
                        super_bound = elm.polygon.getBounds();
                        return true;
                    }

                    super_bound = super_bound.union(elm.polygon.getBounds());
                    return true;
                });

                if (!(super_bound === null)) {
                    map.fitBounds(super_bound);
                    map_references_bound[map.__index] = super_bound;
                }

                $(xmap.map_elm).parents('div.hideme:first').removeClass('active');

                return true;
            });


            return true;
        });

        return true;
    }

    if (!google.maps.Polygon.prototype.getBounds) {
        google.maps.Polygon.prototype.getBounds = function (latLng) {

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
    google.maps.event.addDomListener(window, 'load', initialize_maps);
}
var Latinise = {};
Latinise.latin_map = {
    "Á": "A",
    "Ă": "A",
    "Ắ": "A",
    "Ặ": "A",
    "Ằ": "A",
    "Ẳ": "A",
    "Ẵ": "A",
    "Ǎ": "A",
    "Â": "A",
    "Ấ": "A",
    "Ậ": "A",
    "Ầ": "A",
    "Ẩ": "A",
    "Ẫ": "A",
    "Ä": "A",
    "Ǟ": "A",
    "Ȧ": "A",
    "Ǡ": "A",
    "Ạ": "A",
    "Ȁ": "A",
    "À": "A",
    "Ả": "A",
    "Ȃ": "A",
    "Ā": "A",
    "Ą": "A",
    "Å": "A",
    "Ǻ": "A",
    "Ḁ": "A",
    "Ⱥ": "A",
    "Ã": "A",
    "Ꜳ": "AA",
    "Æ": "AE",
    "Ǽ": "AE",
    "Ǣ": "AE",
    "Ꜵ": "AO",
    "Ꜷ": "AU",
    "Ꜹ": "AV",
    "Ꜻ": "AV",
    "Ꜽ": "AY",
    "Ḃ": "B",
    "Ḅ": "B",
    "Ɓ": "B",
    "Ḇ": "B",
    "Ƀ": "B",
    "Ƃ": "B",
    "Ć": "C",
    "Č": "C",
    "Ç": "C",
    "Ḉ": "C",
    "Ĉ": "C",
    "Ċ": "C",
    "Ƈ": "C",
    "Ȼ": "C",
    "Ď": "D",
    "Ḑ": "D",
    "Ḓ": "D",
    "Ḋ": "D",
    "Ḍ": "D",
    "Ɗ": "D",
    "Ḏ": "D",
    "ǲ": "D",
    "ǅ": "D",
    "Đ": "D",
    "Ƌ": "D",
    "Ǳ": "DZ",
    "Ǆ": "DZ",
    "É": "E",
    "Ĕ": "E",
    "Ě": "E",
    "Ȩ": "E",
    "Ḝ": "E",
    "Ê": "E",
    "Ế": "E",
    "Ệ": "E",
    "Ề": "E",
    "Ể": "E",
    "Ễ": "E",
    "Ḙ": "E",
    "Ë": "E",
    "Ė": "E",
    "Ẹ": "E",
    "Ȅ": "E",
    "È": "E",
    "Ẻ": "E",
    "Ȇ": "E",
    "Ē": "E",
    "Ḗ": "E",
    "Ḕ": "E",
    "Ę": "E",
    "Ɇ": "E",
    "Ẽ": "E",
    "Ḛ": "E",
    "Ꝫ": "ET",
    "Ḟ": "F",
    "Ƒ": "F",
    "Ǵ": "G",
    "Ğ": "G",
    "Ǧ": "G",
    "Ģ": "G",
    "Ĝ": "G",
    "Ġ": "G",
    "Ɠ": "G",
    "Ḡ": "G",
    "Ǥ": "G",
    "Ḫ": "H",
    "Ȟ": "H",
    "Ḩ": "H",
    "Ĥ": "H",
    "Ⱨ": "H",
    "Ḧ": "H",
    "Ḣ": "H",
    "Ḥ": "H",
    "Ħ": "H",
    "Í": "I",
    "Ĭ": "I",
    "Ǐ": "I",
    "Î": "I",
    "Ï": "I",
    "Ḯ": "I",
    "İ": "I",
    "Ị": "I",
    "Ȉ": "I",
    "Ì": "I",
    "Ỉ": "I",
    "Ȋ": "I",
    "Ī": "I",
    "Į": "I",
    "Ɨ": "I",
    "Ĩ": "I",
    "Ḭ": "I",
    "Ꝺ": "D",
    "Ꝼ": "F",
    "Ᵹ": "G",
    "Ꞃ": "R",
    "Ꞅ": "S",
    "Ꞇ": "T",
    "Ꝭ": "IS",
    "Ĵ": "J",
    "Ɉ": "J",
    "Ḱ": "K",
    "Ǩ": "K",
    "Ķ": "K",
    "Ⱪ": "K",
    "Ꝃ": "K",
    "Ḳ": "K",
    "Ƙ": "K",
    "Ḵ": "K",
    "Ꝁ": "K",
    "Ꝅ": "K",
    "Ĺ": "L",
    "Ƚ": "L",
    "Ľ": "L",
    "Ļ": "L",
    "Ḽ": "L",
    "Ḷ": "L",
    "Ḹ": "L",
    "Ⱡ": "L",
    "Ꝉ": "L",
    "Ḻ": "L",
    "Ŀ": "L",
    "Ɫ": "L",
    "ǈ": "L",
    "Ł": "L",
    "Ǉ": "LJ",
    "Ḿ": "M",
    "Ṁ": "M",
    "Ṃ": "M",
    "Ɱ": "M",
    "Ń": "N",
    "Ň": "N",
    "Ņ": "N",
    "Ṋ": "N",
    "Ṅ": "N",
    "Ṇ": "N",
    "Ǹ": "N",
    "Ɲ": "N",
    "Ṉ": "N",
    "Ƞ": "N",
    "ǋ": "N",
    "Ñ": "N",
    "Ǌ": "NJ",
    "Ó": "O",
    "Ŏ": "O",
    "Ǒ": "O",
    "Ô": "O",
    "Ố": "O",
    "Ộ": "O",
    "Ồ": "O",
    "Ổ": "O",
    "Ỗ": "O",
    "Ö": "O",
    "Ȫ": "O",
    "Ȯ": "O",
    "Ȱ": "O",
    "Ọ": "O",
    "Ő": "O",
    "Ȍ": "O",
    "Ò": "O",
    "Ỏ": "O",
    "Ơ": "O",
    "Ớ": "O",
    "Ợ": "O",
    "Ờ": "O",
    "Ở": "O",
    "Ỡ": "O",
    "Ȏ": "O",
    "Ꝋ": "O",
    "Ꝍ": "O",
    "Ō": "O",
    "Ṓ": "O",
    "Ṑ": "O",
    "Ɵ": "O",
    "Ǫ": "O",
    "Ǭ": "O",
    "Ø": "O",
    "Ǿ": "O",
    "Õ": "O",
    "Ṍ": "O",
    "Ṏ": "O",
    "Ȭ": "O",
    "Ƣ": "OI",
    "Ꝏ": "OO",
    "Ɛ": "E",
    "Ɔ": "O",
    "Ȣ": "OU",
    "Ṕ": "P",
    "Ṗ": "P",
    "Ꝓ": "P",
    "Ƥ": "P",
    "Ꝕ": "P",
    "Ᵽ": "P",
    "Ꝑ": "P",
    "Ꝙ": "Q",
    "Ꝗ": "Q",
    "Ŕ": "R",
    "Ř": "R",
    "Ŗ": "R",
    "Ṙ": "R",
    "Ṛ": "R",
    "Ṝ": "R",
    "Ȑ": "R",
    "Ȓ": "R",
    "Ṟ": "R",
    "Ɍ": "R",
    "Ɽ": "R",
    "Ꜿ": "C",
    "Ǝ": "E",
    "Ś": "S",
    "Ṥ": "S",
    "Š": "S",
    "Ṧ": "S",
    "Ş": "S",
    "Ŝ": "S",
    "Ș": "S",
    "Ṡ": "S",
    "Ṣ": "S",
    "Ṩ": "S",
    "Ť": "T",
    "Ţ": "T",
    "Ṱ": "T",
    "Ț": "T",
    "Ⱦ": "T",
    "Ṫ": "T",
    "Ṭ": "T",
    "Ƭ": "T",
    "Ṯ": "T",
    "Ʈ": "T",
    "Ŧ": "T",
    "Ɐ": "A",
    "Ꞁ": "L",
    "Ɯ": "M",
    "Ʌ": "V",
    "Ꜩ": "TZ",
    "Ú": "U",
    "Ŭ": "U",
    "Ǔ": "U",
    "Û": "U",
    "Ṷ": "U",
    "Ü": "U",
    "Ǘ": "U",
    "Ǚ": "U",
    "Ǜ": "U",
    "Ǖ": "U",
    "Ṳ": "U",
    "Ụ": "U",
    "Ű": "U",
    "Ȕ": "U",
    "Ù": "U",
    "Ủ": "U",
    "Ư": "U",
    "Ứ": "U",
    "Ự": "U",
    "Ừ": "U",
    "Ử": "U",
    "Ữ": "U",
    "Ȗ": "U",
    "Ū": "U",
    "Ṻ": "U",
    "Ų": "U",
    "Ů": "U",
    "Ũ": "U",
    "Ṹ": "U",
    "Ṵ": "U",
    "Ꝟ": "V",
    "Ṿ": "V",
    "Ʋ": "V",
    "Ṽ": "V",
    "Ꝡ": "VY",
    "Ẃ": "W",
    "Ŵ": "W",
    "Ẅ": "W",
    "Ẇ": "W",
    "Ẉ": "W",
    "Ẁ": "W",
    "Ⱳ": "W",
    "Ẍ": "X",
    "Ẋ": "X",
    "Ý": "Y",
    "Ŷ": "Y",
    "Ẏ": "Y",
    "Ỵ": "Y",
    "Ỳ": "Y",
    "Ƴ": "Y",
    "Ỷ": "Y",
    "Ỿ": "Y",
    "Ȳ": "Y",
    "Ɏ": "Y",
    "Ỹ": "Y",
    "Ź": "Z",
    "Ž": "Z",
    "Ẑ": "Z",
    "Ⱬ": "Z",
    "Ż": "Z",
    "Ẓ": "Z",
    "Ȥ": "Z",
    "Ẕ": "Z",
    "Ƶ": "Z",
    "Ĳ": "IJ",
    "Œ": "OE",
    "ᴀ": "A",
    "ᴁ": "AE",
    "ʙ": "B",
    "ᴃ": "B",
    "ᴄ": "C",
    "ᴅ": "D",
    "ᴇ": "E",
    "ꜰ": "F",
    "ɢ": "G",
    "ʛ": "G",
    "ʜ": "H",
    "ɪ": "I",
    "ʁ": "R",
    "ᴊ": "J",
    "ᴋ": "K",
    "ʟ": "L",
    "ᴌ": "L",
    "ᴍ": "M",
    "ɴ": "N",
    "ᴏ": "O",
    "ɶ": "OE",
    "ᴐ": "O",
    "ᴕ": "OU",
    "ᴘ": "P",
    "ʀ": "R",
    "ᴎ": "N",
    "ᴙ": "R",
    "ꜱ": "S",
    "ᴛ": "T",
    "ⱻ": "E",
    "ᴚ": "R",
    "ᴜ": "U",
    "ᴠ": "V",
    "ᴡ": "W",
    "ʏ": "Y",
    "ᴢ": "Z",
    "á": "a",
    "ă": "a",
    "ắ": "a",
    "ặ": "a",
    "ằ": "a",
    "ẳ": "a",
    "ẵ": "a",
    "ǎ": "a",
    "â": "a",
    "ấ": "a",
    "ậ": "a",
    "ầ": "a",
    "ẩ": "a",
    "ẫ": "a",
    "ä": "a",
    "ǟ": "a",
    "ȧ": "a",
    "ǡ": "a",
    "ạ": "a",
    "ȁ": "a",
    "à": "a",
    "ả": "a",
    "ȃ": "a",
    "ā": "a",
    "ą": "a",
    "ᶏ": "a",
    "ẚ": "a",
    "å": "a",
    "ǻ": "a",
    "ḁ": "a",
    "ⱥ": "a",
    "ã": "a",
    "ꜳ": "aa",
    "æ": "ae",
    "ǽ": "ae",
    "ǣ": "ae",
    "ꜵ": "ao",
    "ꜷ": "au",
    "ꜹ": "av",
    "ꜻ": "av",
    "ꜽ": "ay",
    "ḃ": "b",
    "ḅ": "b",
    "ɓ": "b",
    "ḇ": "b",
    "ᵬ": "b",
    "ᶀ": "b",
    "ƀ": "b",
    "ƃ": "b",
    "ɵ": "o",
    "ć": "c",
    "č": "c",
    "ç": "c",
    "ḉ": "c",
    "ĉ": "c",
    "ɕ": "c",
    "ċ": "c",
    "ƈ": "c",
    "ȼ": "c",
    "ď": "d",
    "ḑ": "d",
    "ḓ": "d",
    "ȡ": "d",
    "ḋ": "d",
    "ḍ": "d",
    "ɗ": "d",
    "ᶑ": "d",
    "ḏ": "d",
    "ᵭ": "d",
    "ᶁ": "d",
    "đ": "d",
    "ɖ": "d",
    "ƌ": "d",
    "ı": "i",
    "ȷ": "j",
    "ɟ": "j",
    "ʄ": "j",
    "ǳ": "dz",
    "ǆ": "dz",
    "é": "e",
    "ĕ": "e",
    "ě": "e",
    "ȩ": "e",
    "ḝ": "e",
    "ê": "e",
    "ế": "e",
    "ệ": "e",
    "ề": "e",
    "ể": "e",
    "ễ": "e",
    "ḙ": "e",
    "ë": "e",
    "ė": "e",
    "ẹ": "e",
    "ȅ": "e",
    "è": "e",
    "ẻ": "e",
    "ȇ": "e",
    "ē": "e",
    "ḗ": "e",
    "ḕ": "e",
    "ⱸ": "e",
    "ę": "e",
    "ᶒ": "e",
    "ɇ": "e",
    "ẽ": "e",
    "ḛ": "e",
    "ꝫ": "et",
    "ḟ": "f",
    "ƒ": "f",
    "ᵮ": "f",
    "ᶂ": "f",
    "ǵ": "g",
    "ğ": "g",
    "ǧ": "g",
    "ģ": "g",
    "ĝ": "g",
    "ġ": "g",
    "ɠ": "g",
    "ḡ": "g",
    "ᶃ": "g",
    "ǥ": "g",
    "ḫ": "h",
    "ȟ": "h",
    "ḩ": "h",
    "ĥ": "h",
    "ⱨ": "h",
    "ḧ": "h",
    "ḣ": "h",
    "ḥ": "h",
    "ɦ": "h",
    "ẖ": "h",
    "ħ": "h",
    "ƕ": "hv",
    "í": "i",
    "ĭ": "i",
    "ǐ": "i",
    "î": "i",
    "ï": "i",
    "ḯ": "i",
    "ị": "i",
    "ȉ": "i",
    "ì": "i",
    "ỉ": "i",
    "ȋ": "i",
    "ī": "i",
    "į": "i",
    "ᶖ": "i",
    "ɨ": "i",
    "ĩ": "i",
    "ḭ": "i",
    "ꝺ": "d",
    "ꝼ": "f",
    "ᵹ": "g",
    "ꞃ": "r",
    "ꞅ": "s",
    "ꞇ": "t",
    "ꝭ": "is",
    "ǰ": "j",
    "ĵ": "j",
    "ʝ": "j",
    "ɉ": "j",
    "ḱ": "k",
    "ǩ": "k",
    "ķ": "k",
    "ⱪ": "k",
    "ꝃ": "k",
    "ḳ": "k",
    "ƙ": "k",
    "ḵ": "k",
    "ᶄ": "k",
    "ꝁ": "k",
    "ꝅ": "k",
    "ĺ": "l",
    "ƚ": "l",
    "ɬ": "l",
    "ľ": "l",
    "ļ": "l",
    "ḽ": "l",
    "ȴ": "l",
    "ḷ": "l",
    "ḹ": "l",
    "ⱡ": "l",
    "ꝉ": "l",
    "ḻ": "l",
    "ŀ": "l",
    "ɫ": "l",
    "ᶅ": "l",
    "ɭ": "l",
    "ł": "l",
    "ǉ": "lj",
    "ſ": "s",
    "ẜ": "s",
    "ẛ": "s",
    "ẝ": "s",
    "ḿ": "m",
    "ṁ": "m",
    "ṃ": "m",
    "ɱ": "m",
    "ᵯ": "m",
    "ᶆ": "m",
    "ń": "n",
    "ň": "n",
    "ņ": "n",
    "ṋ": "n",
    "ȵ": "n",
    "ṅ": "n",
    "ṇ": "n",
    "ǹ": "n",
    "ɲ": "n",
    "ṉ": "n",
    "ƞ": "n",
    "ᵰ": "n",
    "ᶇ": "n",
    "ɳ": "n",
    "ñ": "n",
    "ǌ": "nj",
    "ó": "o",
    "ŏ": "o",
    "ǒ": "o",
    "ô": "o",
    "ố": "o",
    "ộ": "o",
    "ồ": "o",
    "ổ": "o",
    "ỗ": "o",
    "ö": "o",
    "ȫ": "o",
    "ȯ": "o",
    "ȱ": "o",
    "ọ": "o",
    "ő": "o",
    "ȍ": "o",
    "ò": "o",
    "ỏ": "o",
    "ơ": "o",
    "ớ": "o",
    "ợ": "o",
    "ờ": "o",
    "ở": "o",
    "ỡ": "o",
    "ȏ": "o",
    "ꝋ": "o",
    "ꝍ": "o",
    "ⱺ": "o",
    "ō": "o",
    "ṓ": "o",
    "ṑ": "o",
    "ǫ": "o",
    "ǭ": "o",
    "ø": "o",
    "ǿ": "o",
    "õ": "o",
    "ṍ": "o",
    "ṏ": "o",
    "ȭ": "o",
    "ƣ": "oi",
    "ꝏ": "oo",
    "ɛ": "e",
    "ᶓ": "e",
    "ɔ": "o",
    "ᶗ": "o",
    "ȣ": "ou",
    "ṕ": "p",
    "ṗ": "p",
    "ꝓ": "p",
    "ƥ": "p",
    "ᵱ": "p",
    "ᶈ": "p",
    "ꝕ": "p",
    "ᵽ": "p",
    "ꝑ": "p",
    "ꝙ": "q",
    "ʠ": "q",
    "ɋ": "q",
    "ꝗ": "q",
    "ŕ": "r",
    "ř": "r",
    "ŗ": "r",
    "ṙ": "r",
    "ṛ": "r",
    "ṝ": "r",
    "ȑ": "r",
    "ɾ": "r",
    "ᵳ": "r",
    "ȓ": "r",
    "ṟ": "r",
    "ɼ": "r",
    "ᵲ": "r",
    "ᶉ": "r",
    "ɍ": "r",
    "ɽ": "r",
    "ↄ": "c",
    "ꜿ": "c",
    "ɘ": "e",
    "ɿ": "r",
    "ś": "s",
    "ṥ": "s",
    "š": "s",
    "ṧ": "s",
    "ş": "s",
    "ŝ": "s",
    "ș": "s",
    "ṡ": "s",
    "ṣ": "s",
    "ṩ": "s",
    "ʂ": "s",
    "ᵴ": "s",
    "ᶊ": "s",
    "ȿ": "s",
    "ɡ": "g",
    "ᴑ": "o",
    "ᴓ": "o",
    "ᴝ": "u",
    "ť": "t",
    "ţ": "t",
    "ṱ": "t",
    "ț": "t",
    "ȶ": "t",
    "ẗ": "t",
    "ⱦ": "t",
    "ṫ": "t",
    "ṭ": "t",
    "ƭ": "t",
    "ṯ": "t",
    "ᵵ": "t",
    "ƫ": "t",
    "ʈ": "t",
    "ŧ": "t",
    "ᵺ": "th",
    "ɐ": "a",
    "ᴂ": "ae",
    "ǝ": "e",
    "ᵷ": "g",
    "ɥ": "h",
    "ʮ": "h",
    "ʯ": "h",
    "ᴉ": "i",
    "ʞ": "k",
    "ꞁ": "l",
    "ɯ": "m",
    "ɰ": "m",
    "ᴔ": "oe",
    "ɹ": "r",
    "ɻ": "r",
    "ɺ": "r",
    "ⱹ": "r",
    "ʇ": "t",
    "ʌ": "v",
    "ʍ": "w",
    "ʎ": "y",
    "ꜩ": "tz",
    "ú": "u",
    "ŭ": "u",
    "ǔ": "u",
    "û": "u",
    "ṷ": "u",
    "ü": "u",
    "ǘ": "u",
    "ǚ": "u",
    "ǜ": "u",
    "ǖ": "u",
    "ṳ": "u",
    "ụ": "u",
    "ű": "u",
    "ȕ": "u",
    "ù": "u",
    "ủ": "u",
    "ư": "u",
    "ứ": "u",
    "ự": "u",
    "ừ": "u",
    "ử": "u",
    "ữ": "u",
    "ȗ": "u",
    "ū": "u",
    "ṻ": "u",
    "ų": "u",
    "ᶙ": "u",
    "ů": "u",
    "ũ": "u",
    "ṹ": "u",
    "ṵ": "u",
    "ᵫ": "ue",
    "ꝸ": "um",
    "ⱴ": "v",
    "ꝟ": "v",
    "ṿ": "v",
    "ʋ": "v",
    "ᶌ": "v",
    "ⱱ": "v",
    "ṽ": "v",
    "ꝡ": "vy",
    "ẃ": "w",
    "ŵ": "w",
    "ẅ": "w",
    "ẇ": "w",
    "ẉ": "w",
    "ẁ": "w",
    "ⱳ": "w",
    "ẘ": "w",
    "ẍ": "x",
    "ẋ": "x",
    "ý": "y",
    "ŷ": "y",
    "ẏ": "y",
    "ỵ": "y",
    "ỳ": "y",
    "ƴ": "y",
    "ỷ": "y",
    "ỿ": "y",
    "ȳ": "y",
    "ẙ": "y",
    "ɏ": "y",
    "ỹ": "y",
    "ź": "z",
    "ž": "z",
    "ẑ": "z",
    "ʑ": "z",
    "ⱬ": "z",
    "ż": "z",
    "ẓ": "z",
    "ȥ": "z",
    "ẕ": "z",
    "ᵶ": "z",
    "ᶎ": "z",
    "ʐ": "z",
    "ƶ": "z",
    "ɀ": "z",
    "ﬀ": "ff",
    "ﬃ": "ffi",
    "ﬄ": "ffl",
    "ﬁ": "fi",
    "ﬂ": "fl",
    "ĳ": "ij",
    "œ": "oe",
    "ﬆ": "st",
    "ₐ": "a",
    "ₑ": "e",
    "ᵢ": "i",
    "ⱼ": "j",
    "ₒ": "o",
    "ᵣ": "r",
    "ᵤ": "u",
    "ᵥ": "v",
    "ₓ": "x"
};
String.prototype.latinise = function () {
    return this.replace(/[^A-Za-z0-9\[\] ]/g, function (a) {
        return Latinise.latin_map[a] || a
    })
};
String.prototype.latinize = String.prototype.latinise;
String.prototype.isLatin = function () {
    return this == this.latinise()
};
