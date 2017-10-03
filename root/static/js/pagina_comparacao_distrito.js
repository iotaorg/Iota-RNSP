var pcd = function() {
    var

        $submit = $('button[type=submit]:first'),
        $cidade = $('select[name="cidade"]:first'),
        $period = $('select[name="period"]:first'),
        $indi = $('select[name="indicador"]:first'),
        $indicadors_input = $('input[name="selected_indicators"]:first'),
        $btn_add = $('.button-add-indicator:first'),

        $table_container = $('#table-container'),
        container_original_html =$table_container.html(),
        table_template = $('.table-selected-indicators:first').clone().wrap('<div></div>').parent().html(),

        max_selected_indicators = $indi.attr('data-max-selected-indicators') * 1,
        selected_indicators_count = $indicadors_input.val().length >= 1 ? $indicadors_input.val().split(',').length : 0,
        _init = function() {

            $btn_add.click(_onclick_btn_add);

            $table_container.on('click', '.xbtn', _onclick_btn_remove);



            // botao só ativo se tiver valor no indicador e quatidade de indicadores nao passou do limite
            $indi.change(function() {
                var xbool = $indi.val() != '' && selected_indicators_count < max_selected_indicators;
                $btn_add.prop('disabled', !xbool);
            });

            // se só tem uma cidade, escolhe sozinho ela
            if ($cidade[0].length == 2) {
                $cidade[0].selectedIndex = 1;
            }

            // força um desenho da tabela
            _indicators_changed();
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
            }


        },
        _onclick_btn_remove = function(e){

            var $tr = $(this).parents('tr:first'),
            indicator = $tr.attr('data-id');

            var current_indicators_str = ',' + $indicadors_input.val() + ',';

            if (current_indicators_str.indexOf(',' + indicator + ',') != -1) {

                var new_val = [];
                $.each( $indicadors_input.val().split(','), function (i, v) {
                    if (v != indicator){
                        new_val.push(v);
                    }
                });


                $indicadors_input.val( new_val.join(','));

                selected_indicators_count--;

                _indicators_changed();
            }


        },
        _indicators_changed = function() {

            $submit.prop('disabled', selected_indicators_count == 0);


            if (selected_indicators_count > 0) {

                var $elm = $(table_template.replace('__NUM__', selected_indicators_count)),
                    row_base = $elm.find('tbody>tr');
                $elm.find('tbody>tr').remove();
                $elm.removeClass('hide');

                if (selected_indicators_count == max_selected_indicators)
                    $elm.addClass('is-full');

                $.each($indicadors_input.val().split(','), function(i, v) {

                    var name = $indi.find('option[value=' + v + ']:first').text(),
                        $row = row_base.clone(false);

                    $row.find('td.indname').text(name);
                    $row.attr('data-id', v);

                    $elm.find('tbody').append($row);

                });

                $table_container.html($elm);

            }else{
                $table_container.html( container_original_html );

            }

        };
    return {
        run: _init
    };
}();

$(function() {
    pcd.run();
});