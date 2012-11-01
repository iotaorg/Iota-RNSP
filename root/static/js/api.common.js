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


$(document).ready(function(){
	var estados_sg = [];
	estados_sg["Acre"] = "AC";
	estados_sg["Alagoas"] = "AL";
	estados_sg["Amapá"] = "AP";
	estados_sg["Amazonas"] = "AM";
	estados_sg["Bahia"] = "BA";
	estados_sg["Ceará"] = "CE";
	estados_sg["Distrito Federal"] = "DF";
	estados_sg["Espírito Santo"] = "ES";
	estados_sg["Goiás"] = "GO";
	estados_sg["Maranhão"] = "MA";
	estados_sg["Mato Grosso"] = "MT";
	estados_sg["Mato Grosso do Sul"] = "MS";
	estados_sg["Minas Gerais"] = "MG";
	estados_sg["Pará"] = "PA";
	estados_sg["Paraíba"] = "PB";
	estados_sg["Paraná"] = "PR";
	estados_sg["Pernambuco"] = "PE";
	estados_sg["Piauí"] = "PI";
	estados_sg["Rio de Janeiro"] = "RJ";
	estados_sg["Rio Grande do Norte"] = "RN";
	estados_sg["Rio Grande do Sul"] = "RS";
	estados_sg["Rondônia"] = "RO";
	estados_sg["Roraima"] = "RR";
	estados_sg["Santa Catarina"] = "SC";
	estados_sg["São Paulo"] = "SP";
	estados_sg["Sergipe"] = "SE";
	estados_sg["Tocantins"] = "TO";
	estados_sg[""] = "";

	$.ajaxSetup({ cache: false });

});
