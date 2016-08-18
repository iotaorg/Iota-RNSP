var md = function () {
    var

    $cidade = $('select[name="cidade"]:first'),
        $region = $('select[name="region"]:first'),
        $indi = $('select[name="indicador"]:first'),
        $formato = $('select[name="formato"]:first'),
        $url = $('input[name="url"]:first'),
        $url2 = $('input[name="url2"]:first'),
        _run = function () {


            $cidade.change(_redo_url);
            $indi.change(_redo_url);
            $formato.change(_redo_url);
            $region.change(_redo_url);

            _redo_url();
        },
        _redo_url = function () {

            var
            formato = $formato.val(),
                cidade = $cidade.val(),
                indi = $indi.val(),
                regiao = $region.val();

            if ($(this).attr('name') == 'cidade') {
                if ((cidade == '') == true) {
                    $region.parents('.regiao:first').addClass("hide");
                    $region.find('option').not('[value=""]').remove();
                } else {
                    $region.parents('.regiao:first').removeClass("hide");
                    $region.attr("disabled", "disabled");
                    _load_regions(cidade);
                }
            }

            var base_uri = '';
            var arquivo = indi ? 'dados.' + formato : 'indicadores.' + formato;
            var url = '';
            if ((cidade == '') == false) {
                url = url + '/' + cidade;
            }

            if ((indi == '') == false) {

                if ((regiao == '') == false) {
                    if (regiao == 'all'){
                        url = url + indi + '/todas-regioes';
                    }else{
                        url = url + '/' + indi;
                        url = url + '/regiao/' + regiao;
                    }
                }else{
                    url = url + '/' + indi;
                }

            }else{
                if ((regiao == '') == false) {
                    if (regiao == 'all'){
                        url = url + '/todas-regioes';
                    }else{
                        url = url + '/regiao/' + regiao;
                    }
                }

            }


            base_uri = 'http://' + window.location.host + url;
            url = base_uri + '/' + arquivo;
            $('#id_link').attr('href', url);
            $url.val(url);


            var url2 = base_uri + '/variaveis.' + formato;
            $('#id_link2').attr('href', url2);
            $url2.val(url2);


        },
        _load_regions = function (for_city) {

            $.ajax({
                type: 'GET',
                dataType: 'json',
                url: '/api/regions/' + for_city,
                success: function (data, textStatus, jqXHR) {
                    var options = '';
                    $.each(data.regions, function (index, value) {
                        options = options + '<option value="' + value.name_url + '">' + value.name + '</option>';
                        if (value.subregions) {
                            $.each(value.subregions, function (index, value) {
                                options = options + '<option value="' + value.name_url + '">&nbsp;&nbsp; ' + value.name + '</option>';
                            });
                        }
                    });


                    $region.find('option').each(function(){
						console.log($(this).val());
						if ($(this).val() != "" && $(this).val() != "all"){
							$(this).remove();
						}
				 //.not(  '[value=""]' | '[value="all"]' ).remove();
					});
                    $region.append($(options));
                    if (options == '')
                        $region.parents('.regiao:first').addClass('hide');
                    $region.removeAttr("disabled");
                },
                error: function (data) {
                    alert("erro ao carregar regioes");
                    $region.removeAttr("disabled");
                }
            });

        };
    return {
        run: _run
    };
}();

$(function () {
    md.run();
});
