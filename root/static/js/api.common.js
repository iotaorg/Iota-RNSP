var api_path = "";
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

var removeAccents = (function() {
  var translate_re = /[öäüÖÄÜáàâãéèêúùûóòôõÁÀÂÉÈÊÚÙÛÓÒÔçÇ]/g;
  var translate = {
	  "ä": "a", "ö": "o", "ü": "u",
	  "Ä": "A", "Ö": "O", "Ü": "U",
	  "á": "a", "à": "a", "â": "a",
	  "é": "e", "è": "e", "ê": "e",
	  "ú": "u", "ù": "u", "û": "u",
	  "ó": "o", "ò": "o", "ô": "o",
	  "Á": "A", "À": "A", "Â": "A",
	  "É": "E", "È": "E", "Ê": "E",
	  "Ú": "U", "Ù": "U", "Û": "U",
	  "Ó": "O", "Ò": "O", "Ô": "O",
	  "ã": "a", "Ã": "A", "ç": "c",
	  "Ç": "C"
   // probably more to come
  };
  return function(s) {
	return ( s.replace(translate_re, function(match) {
	  return translate[match];
	}) );
  }
})();

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

});
function updateURLParameter(url, param, paramVal){
            var newAdditionalURL = "";
            var tempArray = url.split("?");
            var baseURL = tempArray[0];
            var additionalURL = tempArray[1];
            var temp = "";
            if (additionalURL) {
                tempArray = additionalURL.split("&");
                for (i=0; i<tempArray.length; i++){
                    if(tempArray[i].split('=')[0] != param){
                        newAdditionalURL += temp + tempArray[i];
                        temp = "&";
                    }
                }
            }

            var rows_txt = temp + "" + param + "=" + paramVal;
            return baseURL + "?" + newAdditionalURL + rows_txt;
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


