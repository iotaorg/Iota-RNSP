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
    node = $('#id_' + id), offset_y = parseInt(node.attr('data-animated-anchor-offset'), 10) || 0;

    window.location.hash = '#' + id;
    $('html, body').animate({
        scrollTop: node.offset().top + offset_y
    }, 600, function(){
        for(i=0;i<1;i++) {
            node.fadeTo(500, 0.5).fadeTo(500, 1.0);
        }
    });
    return false;
});

$(window).load(function(){
    var hash = window.location.hash, who = hash ? $('a[href="'+hash+'"]:first') : null;
    if (who){
        who.click();
    }
});