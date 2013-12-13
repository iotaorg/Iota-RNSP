$(document).ready(function() {

    var need_visualization = $('.visualization')[0];
    var need_google = need_visualization ? true : false;

    if (need_google) {
        $.getScript( "https://www.google.com/jsapi", function( data, textStatus, jqxhr ) {

            if (need_visualization){
                google.load(
                    'visualization', '1.1', {
                        packages: ['geochart'],
                        callback: function(){
                            $events.run('google_visualization');
                        }
                    }
                );

            }

        });
    }

    var $container = $('#container2');

      $container.isotope({
            itemSelector: '.element',
            resizable: false,
      });

});

$(window).smartresize(function(){
    var $container = $('#container2');
  $container.isotope({
    // update columnWidth to a percentage of container width
    masonry: { columnWidth: $container.width() / 2 }
  });
});
