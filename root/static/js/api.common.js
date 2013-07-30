var api_path = "";
var infowindow;
var _show_info_name = function(event){
    infowindow.setContent(this._data.name);
    infowindow.setPosition(event.latLng);

    infowindow.open(this._data.map);
};
//var api_path = "http://rnsp.aware.com.br";
var _last_width=0;

if (!String.prototype.render) {
	String.prototype.render = function(args) {
		var copy = this + '';
		for (var i in args) {
			copy = copy.replace(RegExp('\\$\\$' + i, 'g'), args[i]);
		}
		return copy;
	};
}


var _on_func = function (e) {
    var $elm = $(e.target);
    if ($elm.hasClass('mapa')){

        var $place = $($elm.attr('href'));
        var idx = $place.find('[map_index]:first').attr('map_index');
        var map = map_references[idx];

        map.fitBounds(map_references_bound[idx]);
    }
};
$('a[data-toggle="tab"]').on('shown',_on_func);

if ('a,,b'.split(',').length < 3) {
    var nativeSplit = nativeSplit || String.prototype.split;
    String.prototype.split = function (s /* separator */, limit) {
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
                            if (arguments[j] === undefined) { match[j] = undefined; }
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
            (limit      ? output : output.concat(this.slice(lastLastIndex)));
    };
}

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

var findInJson = function(obj,key,value){
	var found = false;
	var key_found = "";
	$.each(obj, function(key1,value1){
		$.each(obj[key1], function(key2,value2){
			if (key2 == key){
				if (value2 == value){
					found = true;
					key_found = key1;
					return false;
				}
			}
		});
	});
	var retorno = {"found": found, "key": key_found}
	return retorno;
}

var	convertDate = function(date,splitter){
	var date_tmp = date.split(splitter);
	var date = date_tmp[0];
	var time = date_tmp[1];

	var date_split = date.split("-");

	return date_split[2] + "/" + date_split[1] + "/" + date_split[0];
}

var convertDateToPeriod = function(date,period){
	if (period == "yearly"){
		return date.split("-")[0];
	}else if (period == "monthly"){
		return date.split("-")[1] + "/" + date.split("-")[0];
	}
}

var findInArray = function(obj,value){
	if (value == "") return true;
	var retorno = false;
	for (a = 0; a < obj.length; a++){
		if (obj[a] == value) retorno = true;
	}
	return retorno;
}


var estados_sg = [];

estados_sg.push(["Acre","AC"]);
estados_sg.push(["Alagoas","AL"]);
estados_sg.push(["Amapá","AP"]);
estados_sg.push(["Amazonas","AM"]);
estados_sg.push(["Bahia","BA"]);
estados_sg.push(["Ceará","CE"]);
estados_sg.push(["Distrito Federal","DF"]);
estados_sg.push(["Espírito Santo","ES"]);
estados_sg.push(["Goiás","GO"]);
estados_sg.push(["Maranhão","MA"]);
estados_sg.push(["Mato Grosso","MT"]);
estados_sg.push(["Mato Grosso do Sul","MS"]);
estados_sg.push(["Minas Gerais","MG"]);
estados_sg.push(["Pará","PA"]);
estados_sg.push(["Paraíba","PB"]);
estados_sg.push(["Paraná","PR"]);
estados_sg.push(["Pernambuco","PE"]);
estados_sg.push(["Piauí","PI"]);
estados_sg.push(["Rio de Janeiro","RJ"]);
estados_sg.push(["Rio Grande do Norte","RN"]);
estados_sg.push(["Rio Grande do Sul","RS"]);
estados_sg.push(["Rondônia","RO"]);
estados_sg.push(["Roraima","RR"]);
estados_sg.push(["Santa Catarina","SC"]);
estados_sg.push(["São Paulo","SP"]);
estados_sg.push(["Sergipe","SE"]);
estados_sg.push(["Tocantins","TO"]);

var paises = [];

paises["br"] = "Brasil";

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
    isNumber: function(o) {
        return ! isNaN(o-0) && o !== null && o !== "" && o !== false;
    },
    formatNumberCustom: function(number, mask ){

        if (number == null){
            return '-';
        }else if ($.isNumber(number)){
            return $.formatNumber(number, mask);
        }else{
            if (number == '-'){
                return '-';
            }else{
                return '<abbr title="$$err">N/D</abbr>'.render({
                    err: number
                });
            }
        }
    },
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
	setUrl: function(args, data){
		var url = window.location.href;

        url = jQuery.param.querystring(url, args);
        if ((url == window.location.href) == false){
            History.pushState(data, null, url);
        }
	}
});

$(document).ready(function(){

	$.ajaxSetup({ cache: false });

});

function updateURLParameter(url, param, paramVal){
    var xx = {};
    xx[param] = paramVal;
    return jQuery.param.querystring(url, xx);
}

function _resize_canvas () {
    var $g = $('#main-graph'), w=$g.parent().width();
    if (w != _last_width){
        $g.attr('width', w);
        $g.attr('height', w * 0.46);
        RGraph.Redraw();
    }
}

$(window).resize(function() {
    _resize_canvas();
});
var map_references = [];
var map_references_bound = [];
var map_index = 0;


if (!(typeof google == "undefined")) {

    var map_used_things = {};
    function initialize_maps() {
        if (typeof load_map == "undefined")
            return false;
        $.grep(load_map, function(xmap){

            if (xmap.polygons.length == 0)
                return true;

            if (!$(xmap.map_elm)[0])
                return true;

            var $elm = $(xmap.map_elm);
            $elm.parents('div.hideme:first').addClass('active');
            $elm.html('');
            var map = new google.maps.Map($(xmap.map_elm)[0], {
                mapTypeId: google.maps.MapTypeId.ROADMAP,
                zoomControl: true,
            });
            map_references[map_index] = map;
            map.__index = map_index;
            $elm.attr('map_index', map_index);
            map_index++;


            if (!infowindow){
                infowindow = new google.maps.InfoWindow();
            }

            var opacity = xmap.opacity ? xmap.opacity : 0.5;

            google.maps.event.addListenerOnce(map, 'idle', function(){

                $.each(xmap.polygons, function(a, elm){


                    $.each(elm.p, function(aa, elm2){

                        if (elm2 == null) return true;


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

                        zoo.polygon._data = elm;
                        zoo.polygon._data.map = map;

                        zoo.polygon.setMap(map);

                        google.maps.event.addListener(zoo.polygon, 'click',_show_info_name);

                        if (typeof map_used_things[xmap.map_elm] == "undefined")
                            map_used_things[xmap.map_elm] = [];

                        map_used_things[xmap.map_elm].push(zoo);

                    });


                });


                var super_bound = null;
                $.each(map_used_things[xmap.map_elm], function(a, elm){

                    if (super_bound == null){
                        super_bound = elm.polygon.getBounds();
                        return true;
                    }

                    super_bound = super_bound.union( elm.polygon.getBounds() );
                });

                if (!(super_bound == null)){
                    map.fitBounds(super_bound);
                    map_references_bound[map.__index] = super_bound;
                }

                $(xmap.map_elm).parents('div.hideme:first').removeClass('active');
            });


        });
    }

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
        }
    }
    google.maps.event.addDomListener(window, 'load', initialize_maps);
}