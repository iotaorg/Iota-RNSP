
var md = function () {
    var
    $rede    = $('select[name="rede"]:first'),
    $cidade  = $('select[name="cidade"]:first'),
    $indi    = $('select[name="indicador"]:first'),
    $formato = $('select[name="formato"]:first'),
    $url     = $('input[name="url"]:first'),
    _run = function(){

        $rede.change(_redo_url);
        $cidade.change(_redo_url);
        $indi.change(_redo_url);
        $formato.change(_redo_url);

        _redo_url();
    },
    _redo_url = function(){

        var
        formato = $formato.val(),
        rede = $rede.val(),cidade = $cidade.val(), indi= $indi.val();

        if (cidade == ''){
            $indi.parents('div.grupo:first').hide();
            indi = '';
        }else{
            $indi.parents('div.grupo:first').show();
        }

        var arquivo = indi ? 'dados.' + formato : 'indicadores.'+formato;
        var url = 'http://rnsp.aware.com.br/' + rede;
        if ((cidade =='')==false){
            url = url + cidade;
        }
        if ((indi =='')==false){
            url = url + '/' + indi;
        }
        url = url + '/' +arquivo;

        $('#id_link').attr('href', url);
        $url.val(url);

    };
    return {
        run: _run
    };
}();

$(function () {
    md.run();
});