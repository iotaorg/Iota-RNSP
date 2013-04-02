if (!(typeof google == "undefined")){
    var geocoder = new google.maps.Geocoder();
    var markers = [];
    var zoom_padrao = 9;
    var mapDefaultLocation = new google.maps.LatLng(-14.2350040, -51.9252800);
}

$(document).ready(function(){

if (!(typeof google == "undefined")){
	$.carregaMarkers = function(){
		$.clearMarkers();
		$(users_list).each(function(index,item){
			if (item.uf == $("#uf_filter").val()){
				$("#bubble-intro").fadeOut("slow");
				var lat = "";
				var lng = "";
				$.ajax({
					async: false,
					type: 'GET',
					dataType: 'json',
					url: api_path + '/api/public/user/$$userid/'.render({
								userid: item.id
						}),
					success: function(data, textStatus, jqXHR){
						if (data.cidade.latitude) lat = data.cidade.latitude;
						if (data.cidade.longitude) lng = data.cidade.longitude;
					}
				});

				if (lat != "" && lng != ""){
					var latlng = new google.maps.LatLng(lat, lng);
					var image = new google.maps.MarkerImage("/static/images/pin.png");

					var marker = new google.maps.Marker({
						position: latlng,
						map: map,
						icon: image,
						draggable: false
					});

					marker.__uf = item.uf;
					marker.__pais = item.pais;
					marker.__uri = item.uri;
					marker.__cidade = item.nome;
					marker.__id = item.id;
					marker.__position = latlng;

					markers.push(marker);

					google.maps.event.addListener(marker, 'click', function(e) {
						$("#bubble-intro").fadeOut("slow");
						map.setCenter(marker.__position);
						if (map.getZoom() < zoom_padrao) map.setZoom(zoom_padrao);
						window.location.href = "/" + marker.__pais.toLowerCase() + "/" + marker.__uf.toLowerCase() + "/" + marker.__uri;
					});

					google.maps.event.addListener(marker, 'mouseover', function(e) {
						$("#bubble-intro").fadeOut("slow");
						$.showInfoCidade(marker);
					});

				}
			}
		});

	}

	$.clearMarkers = function(){
		if (markers.length && markers.length == 0) return;
		$.each(markers, function(i, marker) {
			marker.setMap(null);
			marker.__uf = null;
			marker.__cidade = null;
		});
		markers = new Array();
	}

	$.carregaComboEstados = function(){

		$(estados_sg).each(function(index,item){
			$("#uf_filter").append("<option value='$$uf'>$$uf".render({uf: item[1]}));
		});

		$("#uf_filter").change(function(){
			$.carregaMarkers();
		});

	}

	$.setaMapaHome = function(){
		if (map){
			map.setCenter(mapDefaultLocation);
			map.setZoom(4);
			google.maps.event.addListener(map, 'center_changed', function () {
				$("#bubble-intro").fadeOut("slow");
			});
			google.maps.event.addListener(map, 'zoom_changed', function () {
				$("#bubble-intro").fadeOut("slow");
			});
		}
	}


	if (ref == "home"){
		var mapOptions = {
			center: mapDefaultLocation,
			zoom: 4,
			mapTypeId: google.maps.MapTypeId.ROADMAP
        };

		var map = new google.maps.Map(document.getElementById("mapa"),mapOptions);
		var boxText = document.createElement("div");
		boxText.style.cssText = "border: 2px solid #20c1c1; margin-top: 8px; background: white; padding: 0px;";
		boxText.innerHTML = "";
		var myOptions = {
			 content: boxText
			,disableAutoPan: false
			,maxWidth: 0
			,pixelOffset: new google.maps.Size(-100, 0)
			,zIndex: null
			,boxStyle: {
			  background: "url('static/images/tipbox.gif') no-repeat"
			  ,opacity: 0.90
			  ,width: "200px"
			 }
			,closeBoxMargin: "10px 2px -13px 2px"
			,closeBoxURL: "http://www.google.com/intl/en_us/mapfiles/close.gif"
			,infoBoxClearance: new google.maps.Size(1, 1)
			,isHidden: false
			,pane: "floatPane"
			,enableEventPropagation: false
		};

		var ib = new InfoBox(myOptions);

		map.controls[google.maps.ControlPosition.TOP_CENTER].push($('#bubble-intro')[0]);
		$('#bubble-intro').show();
		$.carregaComboEstados();
		$.setaMapaHome();
	}

    $.showInfoCidade = function(marker){
        boxTextContent = "<div style='padding: 2px 4px; text-align: center;'>";
        boxTextContent += marker.__cidade + " - " + marker.__uf;
        boxTextContent += "</div>";

        boxText.innerHTML = boxTextContent;
        ib.close();
        ib.setContent(boxText);
        ib.open(map, marker);
    }
}


});

