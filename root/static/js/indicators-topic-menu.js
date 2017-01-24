$(document).ready(function() {
    var $groups = $('#topic_group_list'),
        $container = $('#topic_indicators_container'),
        $list = $('#topic_indicators_list'),
        $search = $('#topic-indicator-search'),
        $status = $('#topic_search_status'),
        _select_caption = '',
        _current_group = $groups.find('.topic_select').attr('selected-id'),
        $select = $groups.find('.topic_select:first'),

        _on_menu_click = function (event) {
			console.log($list);
            var $me = $(event.target);
            if (typeof $me.attr('group-id') !== "undefined") {

                _select_caption = $me.text();
                _current_group = $me.attr('group-id');
				console.log(_current_group);
                // todo mundo
                if (_current_group === '0') {
                    $list.find('.topic_item').removeClass('hideimp');
                } else {
                    $list.find('.topic_item').addClass('hideimp');
                    $list.find('.topic_item.g' + _current_group).removeClass('hideimp');
                }
                __old_search_val2 = '';
                _do_search();
            }

            if ($groups.find('.topic_options:first').is(':visible')) {

                $select.text(_select_caption);
				console.log(_select_caption);
                $select.removeClass('open');

                $groups.find('.topic_options:first').hide();

                $container.show();

            } else {
                _select_caption = $select.text();
                $select.text($select.attr('data-select-title'));
                $select.addClass('open');

                $container.hide();
                $groups.find('.topic_options:first').show();
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
			console.log(match);
            var matches = $('.topic_indicators .topic_item').filter(function () {

                var re = new RegExp(match, ''),
                    _true = re.test(normalize($(this).text().trim()));

                if (_true) {_count++;}

                return _true;
            });


            $list.find('.topic_item').addClass('hideimp');

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
                $list.find('.topic_item.hideimp').removeClass('hideimp');
            } else {
                if (__old_search_val === '') {
                    $list.find('.topic_item').addClass('hideimp');
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


    $list.find('.topic_item').tooltip();

    $status.click(_show_all);
    $search.keyup(debounce(_search_status, 30));

    $groups.click(_on_menu_click);
    $select.disableSelection();

    if ($(window).width() > 740) {

        if ( $list.hasClass('auto-height') ){
            $list.css('height', Math.max($(window).height() - 286, 465));
        }

        $list.css('overflow', 'auto');
    }

    if ( $select.hasClass('open-me')){
        $groups.find('.option:first').click();
    }

});
