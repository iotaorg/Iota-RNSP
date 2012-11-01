if (!eixos){

	if ($.cookie("key") != undefined || $.cookie("key") != null){
	
		var carregaEixos = false;
		
		var eixos = {};
		
		$.ajax({
			type: 'GET',
			dataType: 'json',
			url: '/api/axis?api_key=$$key'.render({
					key: $.cookie("key")
					}),
			success: function(data, textStatus, jqXHR){
				$.each(data.axis, function(index,value){
					eixos[String(data.axis[index].id)] = String(data.axis[index].name);
				});
				
				if (carregaEixos){
					$.each(eixos,function(key, value){
						$("#dashboard-content .content select#axis").append($("<option></option>").val(key).html(value));
					});
					carregaEixos = false;
				}
				
			},
			error: function(data){
				$("#aviso").setWarning({msg: "Erro ao carregar ($$codigo)".render({
							codigo: $.parseJSON(data.responseText).error
						})
				});
			}
		});
	}
}
/*
var eixos = {
				"11":"Ação Local para a Saúde",
				"2":"Bens Naturais Comuns",
				"9":"Consumo Responsável e Opções de Estilo de Vida",
				"6":"Cultura para a sustentabilidade",
				"12":"Do Local para o Global",
				"8":"Economia Local, Dinâmica, Criativa e Sustentável",
				"7":"Educação para a Sustentabilidade e Qualidade de Vida",
				"3":"Equidade, Justiça Social e Cultura de Paz",
				"4":"Gestão Local para a Sustentabilidade",
				"1":"Governança",
				"10":"Melhor Mobilidade, Menos Tráfego",
				"5":"Planejamento e Desenho Urbano",
				"13":"Planejando Cidades do Futuro"
			};*/