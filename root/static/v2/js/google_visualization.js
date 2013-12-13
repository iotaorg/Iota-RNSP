var $google_visualization = function (){

    var run = function( ){

        $('.visualization-countries').each(function(i, e){
            $google_visualization_countries.run(e);
        });

    };

    return { run: run };
}();
var $google_visualization_countries = function (){

    var $elm, run = function(elm){

        $elm = $(elm);

        var data = new google.visualization.DataTable();

        data.addColumn('string', 'Country');
        data.addColumn('number', 'Value');
        data.addColumn({
            type: 'string',
            role: 'tooltip'
        });
        var ivalue = new Array(), colors = new Array(),
        ixindex = new Array(),
        region = 'world';


        if ($('#country-container .country-item').length == 1) {
            region = 'BR';
            $('#states-container .list-state').each(function(i, e){
                var $e = $(e);
                ixindex.push($e);
                //colors.push($e.css('borderLeftColor'));
                ivalue.push([
                    $e.text(),
                    i,
                    $e.text()
                ]);
            });

        }else{
            $('#country-container .country-item').each(function(i, e){
                var $e = $(e);
                ixindex.push($e);
                colors.push($e.css('backgroundColor'));
                ivalue.push([
                    $e.text(),
                    i,
                    $e.text()
                ]);
            });
        }
        data.addRows(ivalue);

        var stateHeatMap = new google.visualization.GeoChart($elm[0]);
        var _on_res_call = function(){
            stateHeatMap.draw(data, {
                width: $elm.width(),
                height: $elm.width() / 1.57,
                region: region,
                resolution: region === 'world' ? 'world' : 'provinces',

                datalessRegionColor: '#EEE',
                backgroundColor: '#d9edff',
                colorAxis: { colors: colors}
            });
        };
        _on_res_call();
        $(window).smartresize(_on_res_call);


        $elm.hide();
        google.visualization.events.addListener(stateHeatMap, 'ready', function(){
            $elm.find('svg>g>g:eq(1)').remove();
            $elm.show();
            $elm.parents('.main_ratio:first').find('.loading').hide();
        });
        google.visualization.events.addListener(stateHeatMap, 'select', function(){
            var ex = stateHeatMap.getSelection()[0];
            if (ex){
                ixindex[ex['row']].click();
            }
        });


    };

    return { run: run };
}();