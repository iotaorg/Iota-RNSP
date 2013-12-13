var $recalc_isotope = function(){

    $('.isotope-container2').each(function(i, o){
        var $container = $(o);
        $container.isotope({
            masonry: { columnWidth: $container.width() / 2 }
        });
    });
    $('.isotope-container4').each(function(i, o){
        var $container = $(o);
        $container.isotope({
            masonry: { columnWidth: $container.width() / 4 }
        });
    });
};

$(document).ready(function() {

    $('.isotope-container2,.isotope-container4').isotope({
        itemSelector: '.element',
        resizable: false,
    });
    $recalc_isotope();
});

$(window).smartresize($recalc_isotope);