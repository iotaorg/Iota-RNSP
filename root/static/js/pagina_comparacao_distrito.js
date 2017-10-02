var pcd = function() {
    var

        $cidade = $('select[name="cidade"]:first'),
        $period = $('select[name="period"]:first'),
        $indi = $('select[name="indicador"]:first'),
        $indicadors_input = $('input[name="selected_indicators"]:first'),
        $btn_add = $('.button-add-indicator:first'),

        max_selected_indicators = $indi.attr('data-max-selected-indicators') * 1,
        selected_indicators_count = $indicadors_input.val().length >= 1 ? $indicadors_input.val().split(',').length : 0,
        _init = function() {

            console.log(selected_indicators_count, max_selected_indicators)

            $btn_add.click(_onclick_btn_add);

            // botao só ativo se tiver valor no indicador e quatidade de indicadores nao passou do limite
            $indi.change(function(){
                var xbool = $indi.val() != '' && selected_indicators_count <= max_selected_indicators;
                $btn_add.prop('disabled', !xbool );
            });

            // se só tem uma cidade, escolhe sozinho ela
            if ($cidade[0].length == 2) {
                $cidade[0].selectedIndex = 1;
            }
        },
        _onclick_btn_add = function() {


            var indicator= $indi.val(), current_indicators_str=  ',' +$indicadors_input.val() + ',' ;

            if ( current_indicators_str.indexOf( ',' + indicator + ',' ) == -1 ){

                $indicadors_input.val( $indicadors_input.val().length == 0 ? indicator : $indicadors_input.val() + ',' + indicator );

                selected_indicators_count++;


            }else{

                alert('Indicador já selecionado!!');

            }


        };
    return {
        run: _init
    };
}();

$(function() {
    pcd.run();
});