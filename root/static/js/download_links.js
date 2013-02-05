
var md = function () {
    var
    $rede    = $('select[name="rede"]:first'),
    $cidade  = $('select[name="cidade"]:first'),
    $indi    = $('select[name="indicador"]:first'),
    $formato = $('select[name="formato"]:first'),
    $url     = $('input[name="url"]:first'),
    $url2    = $('input[name="url2"]:first'),
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


        var base_uri = '';
        var arquivo = indi ? 'dados.' + formato : 'indicadores.'+formato;
        var url = 'http://rnsp.aware.com.br/' + rede;
        if ((cidade =='')==false){
            url = url + '/' +  cidade;
        }
        if ((indi =='')==false){
            url = url + '/' + indi;
        }
        base_uri = url;

        url = base_uri + '/' +arquivo;
        $('#id_link').attr('href', url);
        $url.val(url);


        var url2 = base_uri + '/variaveis.'+formato;
        $('#id_link2').attr('href', url2);
        $url2.val(url2);


    };
    return {
        run: _run
    };
}();

$(function () {
    md.run();
});