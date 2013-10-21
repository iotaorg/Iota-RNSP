var $events = function (){

    var run = function( name ){


        if ( name === 'google_visualization') {
            $google_visualization.run();
        }

    };

    return { run: run };
}();