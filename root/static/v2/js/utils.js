function debounce(fn, delay) {
    var timer = null;
    return function () {
        var context = this,
            args = arguments;
        clearTimeout(timer);
        timer = setTimeout(function () {
            fn.apply(context, args);
        }, delay);
    };
}
$.fn.disableSelection = function () {
    return this.attr('unselectable', 'on')
        .css('user-select', 'none')
        .on('selectstart', false);
};

$('html').on('click', 'a[data-animated-anchor]', function(){
    var me=$(this), hash = me.attr('href'), id = hash.replace('#', ''),
    node = $(hash), offset_y = parseInt(node.attr('data-animated-anchor-offset'), 10) || 0;

    node.removeAttr('id');

    window.location.hash = hash;

    node.attr('id', id);

    $('html, body').animate({
        scrollTop: node.offset().top + offset_y
    }, 600, function(){

        for(i=0;i<1;i++) {
            node.fadeTo(500, 0.5).fadeTo(500, 1.0);
        }

    });
    return false;
});

$(function(){
    var hash = window.location.hash, who = hash ? $('a[href="'+hash+'"]') : null;

    if (who){
        who.click();
    }
});