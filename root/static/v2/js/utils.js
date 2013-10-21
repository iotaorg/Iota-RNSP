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

