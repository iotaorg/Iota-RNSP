/*!
 * jQuery lockfixed plugin
 * http://www.directlyrics.com/code/lockfixed/
 *
 * Copyright 2012 Yvo Schaap
 * Released under the MIT license
 * http://www.directlyrics.com/code/lockfixed/license.txt
 *
 * Date: Sun Jan 27 2013 12:00:00 GMT
 */
(function($, undefined){
    $.extend({
        /**
         * Lockfixed initiated
         * @param {Object} el - a jquery element, DOM node or selector string
         * @param {Object} config - offset - forcemargin
         */
        "lockfixed": function(el, config){
            if (config && config.offset) {
                config.offset.bottom = parseInt(config.offset.bottom,10);
                config.offset.top = parseInt(config.offset.top,10);
            }else{
                config.offset = {bottom: 0, top: 0};
            }
            var el =$(el).first();

            var affected = false;
            if(el && el.offset()){
                var
                pai = el.parents('.row:first'),
                el_left = el.offset().left,
                el_height = el.outerHeight(true),
                el_width = el.outerWidth(),
                el_position = el.css("position"),
                el_position_top = el.css("top"),
                el_margin_top = parseInt(el.css("marginTop"),10),
                top = 0,
                disabled = false,
                pos_not_fixed = false;

                el_margin_top = el_margin_top ? el_margin_top : 0;

                /* we prefer feature testing, too much hassle for the upside */
                /* while prettier to use position: fixed (less jitter when scrolling) */
                /* iOS 5+ + Andriud has fixed support, but issue with toggeling between fixed and not and zoomed view, is iOs only calls after scroll is done, so we ignore iOS 5 for now */
                if (config.forcemargin === true || navigator.userAgent.match(/\bMSIE (4|5|6)\./) || navigator.userAgent.match(/\bOS (3|4|5|6)_/) || navigator.userAgent.match(/\bAndroid (1|2|3|4)\./i)){
                    pos_not_fixed = true;
                }

                $(window).bind('scroll resize orientationchange load',el,function(e){
                    if (e.type != 'scroll'){
                        var restore_default = false;

                        if (pai.width() < el_width || $(window).width() < 768){
                            restore_default = true;
                        }

                        disabled = restore_default;
                        if (restore_default && affected){
                            el.css({'position': el_position,'top': el_position_top, 'width': 'auto', 'marginTop': el_margin_top +"px"});
                        }

                        if (e.type == 'resize'){
                            el.css({'position': el_position,'top': el_position_top, 'width': 'auto', 'marginTop': el_margin_top +"px"});
                            el_width = el.width();
                        }
                    }
                    if (disabled) return;

                    var scroll_top = $(window).scrollTop(),
                               el_top = el.offset().top;

                    //if we have a input focus don't change this (for ios zoom and stuff)
                    if(pos_not_fixed && document.activeElement && document.activeElement.nodeName === "INPUT"){
                        return;
                    }

                    affected = true;
                    //if (scroll_top >= (el_top-el_margin_top -config.offset.top)){
                    if (scroll_top +config.offset.top > pai.offset().top) {

                        if (pos_not_fixed){
                            //if we have another element above with a new margin, we have a problem (double push down)
                            //recode to position: absolute, with a relative parent
                            el.css({'marginTop': parseInt((el_margin_top  + (scroll_top - el_top - top) + 2 * config.offset.top),10)+'px'});
                        }else{
                            var out_h = pai.outerHeight(),
                            distancia =  pai.position().top + out_h;

                            var el_height = el.outerHeight();

                            if (scroll_top > distancia-el_height -config.offset.top-el_margin_top ){
                                if (el.css('position') != 'static'){
                                    el.css({
                                        'position': 'static',
                                        'marginTop':(out_h-el_height+el_margin_top )+'px',
                                        'width':el_width +"px"
                                    });
                                }

                            }else{
                                el.css({
                                        'position': 'fixed',
                                       'top':(config.offset.top+el_margin_top)+'px',
                                       'width':el_width +"px",
                                       marginTop: el_margin_top
                                });
                            }
                        }
                    }else{
                        el.css({'position': el_position,'top': el_position_top, 'width':el_width +"px", 'marginTop': el_margin_top +"px"});
                    }
                });
            }

        }
    });
})(jQuery);