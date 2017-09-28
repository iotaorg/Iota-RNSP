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


    $('.isotope-container').each(function(i, o){
        var $container = $(o);
        $container.isotope({});
    });
};

$(document).ready(function() {

    $('.isotope-container2,.isotope-container4,.isotope-container').isotope({
        itemSelector: '.element',
        resizable: false,
    });
    $recalc_isotope();
});

setTimeout($recalc_isotope, 1000);
setTimeout($recalc_isotope, 5000);
setInterval($recalc_isotope, 15000);

$(window).smartresize($recalc_isotope);