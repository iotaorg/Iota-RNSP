$(document).ready(function() {
    var $groups = $('#group_list'),
        $container = $('#indicators_container'),
        $list = $('#indicators_list'),
        $search = $('#indicator-search'),
        $status = $('#search_status'),

        _frase_inicial='<div class="text">Em conformidade com os novos parâmetros de desenvolvimento da ONU, esse eixo do Programa Cidades Sustentáveis dialoga com os ODS:</div>',

        _select_caption = '',
        _current_group = $groups.find('.select').attr('selected-id'),
        $select = $groups.find('.select:first'),
        is_infancia = $select.hasClass('infancia'),
        _on_menu_click = function (event) {
            var $me = $(event.target);
            var $ods= $('#menu-ods');
            $ods.html('');

            $me.parent().find('.option.active').removeClass('active');

            if (typeof $me.attr('group-id') !== "undefined") {

                _select_caption = $me.text();
                _current_group = $me.attr('group-id');

                $me.addClass('active');

                // todo mundo
                if (_current_group === '0') {
                    $list.find('.item').removeClass('hideimp');

                    if ($ods){
                        $ods.hide();
                    }

                } else {
                    $list.find('.item').addClass('hideimp');
                    $list.find('.item.g' + _current_group).removeClass('hideimp');

                    if ($ods && $me.attr('data-attrs') && $me.attr('data-attrs').length > 2 ){

                        var $obj = $.parseJSON($me.attr('data-attrs'));
                        var x = _frase_inicial;
                        $.each($obj, function(i, o) {
                            x += '<div class="bs-tooltip iods iods-'+o.code +'" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="'+o.props.name+'"></div>';
                        });
                        $ods.html(x).find('.bs-tooltip').tooltip();
                        $ods.show();
                    }

                }

                __old_search_val2 = '';
                _do_search();
            }else{
                _select_caption='';
            }


            if (is_infancia){
                 // nao escolheu nenhum item
                if (_select_caption == ''){

                    // clicou duas vezes no menu = fechar tudo
                    if ($groups.find('.options:first').is(':visible')) {

                        $select.removeClass('open');

                        $groups.find('.options:first').hide();
                        $container.hide();
                        $ods.hide();

                    }else{

                        $select.addClass('open');

                        $groups.find('.options:first').show();
                    }


                }else{

                    $container.show();
                }

            }else{

                if ($groups.find('.options:first').is(':visible')) {
                    $select.text(_select_caption);
                    $select.removeClass('open');

                    $groups.find('.options:first').hide();

                    $container.show();
                } else {

                    _select_caption = $select.text();
                    $select.text($select.attr('data-select-title'));
                    $select.addClass('open');

                    $container.hide();
                    $groups.find('.options:first').show();
                }
            }

            return false;
        },
        __old_search_val2 = '',
        _do_search = function () {
            var val = $search.val().trim();

            if (__old_search_val2 == val || val === '') {
                return false;
            }
            __old_search_val2 = val;

            var match = normalize(val),
                _count = 0;
            match = match.replace(/\s+/g, '.+');

            var matches = $('.indicators .item').filter(function () {

                var re = new RegExp(match, ''),
                    _true = re.test(normalize($(this).text().trim()));

                if (_true) {_count++;}

                return _true;
            });


            $list.find('.item').addClass('hideimp');

            if (_current_group != '0') {
                $(matches).each(function (index) {
                    var $ind = $(this);
                    if ($ind.hasClass("g" + _current_group)) {
                        $ind.removeClass('hideimp');
                        _count--;
                    }
                });

                if (_count === 0) {
                    $status.addClass('hideimp');

                    $search.addClass('input-invalid');

                } else {
                    $search.removeClass('input-invalid');
                    $status.text($status.attr('data-text').replace('__NUM__', _count));
                    $status.removeClass('hideimp');
                }

            } else {
                if (_count === 0) {
                    $search.addClass('input-invalid');
                } else {
                    $search.removeClass('input-invalid');
                }

                $status.addClass('hideimp');
                $(matches).removeClass('hideimp');
            }

            return true;
        },
        __old_search_val = '',
        _search_int = null,
        _search_status = function () {
            var $me = $(this),
                val = $me.val().trim();

            if (__old_search_val == val) {
                return false;
            }

            if (val === '') {
                $list.find('.item.hideimp').removeClass('hideimp');
            } else {
                if (__old_search_val === '') {
                    $list.find('.item').addClass('hideimp');
                }
                clearInterval(_search_int);
                _search_int = setTimeout(_do_search, 110);
            }
            __old_search_val = val;
            return true;
        },
        _show_all = function () {
            // abre o select no primeiro click, depois seleciona 'todos'
            $groups.find('.option:first').click().click();
        };


    $list.find('.item').tooltip();

    $status.click(_show_all);
    $search.keyup(debounce(_search_status, 20));

    $groups.click(_on_menu_click);
    $select.disableSelection();

    if ($(window).width() > 740) {

        if ( $list.hasClass('auto-height') ){
            $list.css('height', Math.max($(window).height() - 286, 465));
        }

        $list.css('overflow', 'auto');
    }

    $groups.after('<div id="menu-ods"></div>');

    if ( is_infancia ){

        $container.hide();

    }else if ( $select.hasClass('open-me')){
        $groups.find('.option:first').click();
    }else{


        var $ods= $('#menu-ods'), $me = $('#group_list').find('.option[group-id="'+_current_group+'"]');
        $ods.html('');

        if ($ods && $me.attr('data-attrs') && $me.attr('data-attrs').length > 2){

            var $obj = $.parseJSON($me.attr('data-attrs'));
            var x = _frase_inicial;
            $.each($obj, function(i, o) {
                x += '<div class="bs-tooltip iods iods-'+o.code +'" data-toggle="tooltip" data-placement="bottom" title="" data-original-title="'+o.props.name+'"></div>';
            });
            $ods.html(x).find('.bs-tooltip').tooltip();
            $ods.show();
        }



    }


});
