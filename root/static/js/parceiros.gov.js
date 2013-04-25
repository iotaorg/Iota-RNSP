(function ($) {
    $(document).ready(function() {
        $("[class^='menu-footer-']").addClass("span2");
        $(".page-resume:first").appendTo($("h1.page-header:first"));
        if ($(".region-navigation ul.menu li.last a").text() == "Mapa do Site"){
            $(".region-navigation ul.menu li.last a").removeClass("active");
            $(".region-navigation ul.menu li.last a").attr("href","#mapa_site");
        }

        $("#block-views-slide-realizacao-block").addClass("span6");
        $("#block-views-slide-apoio-block").addClass("span6");
        $("#block-views-slide-apoio-midia-block").addClass("span4");
        $("#block-views-slide-parceiros-block").addClass("span4");
        $("#block-views-d01ac43290f06ee830fff0017a534c6d").addClass("span4");
        $("#block-views-slide-patrocinadores-block").addClass("span12");

        if ($(".region-partners section").length > 0){


            function initScroll(name){
                $("#scroll-" + name + " img").each(function(index,item){
                    $(this).attr("n-index",index);
                });
            }

            function setScroll(name){
                $("#scroll-" + name + " img:visible").hide();
                showScroll(name);
            }

            function showScroll(name){
                if (name != "patrocinadores"){
                    if ($("#scroll-" + name).width() <= 228){
                        cTotalScroll[name] = 2;
                    }else if ($("#scroll-" + name).width() > 228 && $("#scroll-" + name).width() <= 370){
                        cTotalScroll[name] = 3;
                    }else if ($("#scroll-" + name).width() >= 715){
                        cTotalScroll[name] = 6;
                    }
                }else{
                    if ($("#scroll-" + name).width() > 940){
                        cTotalScroll[name] = 10;
                    }else if ($("#scroll-" + name).width() <= 940 && $("#scroll-" + name).width() > 724){
                        cTotalScroll[name] = 8;
                    }else if ($("#scroll-" + name).width() <= 724 && $("#scroll-" + name).width() > 425){
                        cTotalScroll[name] = 5;
                    }else if ($("#scroll-" + name).width() <= 425 && $("#scroll-" + name).width() > 271){
                        cTotalScroll[name] = 3;
                    }else if ($("#scroll-" + name).width() <= 271){
                        cTotalScroll[name] = 2;
                    }
                }

                for (i = 0; i < cTotalScroll[name]; i++){
                    if (cScroll[name] < $("#scroll-" + name + " img").length){
                        $("#scroll-" + name + " img[n-index=" + cScroll[name] + "]").fadeIn();
                        cScroll[name] = cScroll[name] + 1;
                    }else{
                        cScroll[name] = 0;
                        $("#scroll-" + name + " img[n-index=" + cScroll[name] + "]").fadeIn();
                        cScroll[name] = cScroll[name] + 1;
                    }
                }

            }

            var new_item;

            $(".slide-realizacao .view-content").prepend("<div id='scroll-realizacao'></div>");
            $(".slide-realizacao .logo-item").each(function(index,item){
                new_item = "<img src='" + $(item).find(".views-field-field-logo img").attr("src") + "' title = '" + $(item).find(".views-field-title .field-content").text() + "' link_logo='" + $(item).find(".views-field-path .field-content").text() + "'>";
                $(".slide-realizacao .view-content #scroll-realizacao").append(new_item);

                $(".slide-realizacao .view-content .logo-item").remove();
            });

            $(".slide-apoio .view-content").prepend("<div id='scroll-apoio'></div>");
            $(".slide-apoio .logo-item").each(function(index,item){
                new_item = "<img src='" + $(item).find(".views-field-field-logo img").attr("src") + "' title = '" + $(item).find(".views-field-title .field-content").text() + "' link_logo='" + $(item).find(".views-field-path .field-content").text() + "'>";
                $(".slide-apoio .view-content #scroll-apoio").append(new_item);

                $(".slide-apoio .view-content .logo-item").remove();
            });

            $(".slide-apoio-midia .view-content").prepend("<div id='scroll-apoio-midia' class='makeMeScrollable'></div>");
            $(".slide-apoio-midia .logo-item").each(function(index,item){
                new_item = "<img src='" + $(item).find(".views-field-field-logo img").attr("src") + "' title = '" + $(item).find(".views-field-title .field-content").text() + "' link_logo='" + $(item).find(".views-field-path .field-content").text() + "'>";
                $(".slide-apoio-midia .view-content #scroll-apoio-midia").append(new_item);

                $(".slide-apoio-midia .view-content .logo-item").remove();
            });

            var tScroll = [];
            var cScroll = [];
            var cTotalScroll = [];

            cScroll["apoio-midia"] = 0;
            cTotalScroll["apoio-midia"] = 3;
            $("#scroll-apoio-midia img").hide();
            initScroll("apoio-midia");
            showScroll("apoio-midia");
            tScroll["apoio-midia"] = setInterval(function(){
                setScroll("apoio-midia");
            },10000);

            $(".slide-parceiros .view-content").prepend("<div id='scroll-parceiros' class='makeMeScrollable'></div>");
            $(".slide-parceiros .logo-item").each(function(index,item){
                new_item = "<img src='" + $(item).find(".views-field-field-logo img").attr("src") + "' title = '" + $(item).find(".views-field-title .field-content").text() + "' link_logo='" + $(item).find(".views-field-path .field-content").text() + "'>";
                $(".slide-parceiros .view-content #scroll-parceiros").append(new_item);

                $(".slide-parceiros .view-content .logo-item").remove();
            });

            cScroll["parceiros"] = 0;
            cTotalScroll["parceiros"] = 3;
            $("#scroll-parceiros img").hide();
            initScroll("parceiros");
            showScroll("parceiros");
            tScroll["parceiros"] = setInterval(function(){
                setScroll("parceiros");
            },10000);

            $(".slide-parceiros-internacionais .view-content").prepend("<div id='scroll-parceiros-internacionais' class='makeMeScrollable'></div>");
            $(".slide-parceiros-internacionais .logo-item").each(function(index,item){
                new_item = "<img src='" + $(item).find(".views-field-field-logo img").attr("src") + "' title = '" + $(item).find(".views-field-title .field-content").text() + "' link_logo='" + $(item).find(".views-field-path .field-content").text() + "'>";
                $(".slide-parceiros-internacionais .view-content #scroll-parceiros-internacionais").append(new_item);

                $(".slide-parceiros-internacionais .view-content .logo-item").remove();
            });

            cScroll["parceiros-internacionais"] = 0;
            cTotalScroll["parceiros-internacionais"] = 3;
            $("#scroll-parceiros-internacionais img").hide();
            initScroll("parceiros-internacionais");
            showScroll("parceiros-internacionais");
            tScroll["parceiros-internacionais"] = setInterval(function(){
                setScroll("parceiros-internacionais");
            },10000);

            $(".slide-patrocinadores .view-content").prepend("<div id='scroll-patrocinadores' class='makeMeScrollable'></div>");
            $(".slide-patrocinadores .logo-item").each(function(index,item){
                new_item = "<img src='" + $(item).find(".views-field-field-logo img").attr("src") + "' title = '" + $(item).find(".views-field-title .field-content").text() + "' link_logo='" + $(item).find(".views-field-path .field-content").text() + "'>";
                $(".slide-patrocinadores .view-content #scroll-patrocinadores").append(new_item);

                $(".slide-patrocinadores .view-content .logo-item").remove();
            });

            cScroll["patrocinadores"] = 0;
            cTotalScroll["patrocinadores"] = 10;
            $("#scroll-patrocinadores img").hide();
            initScroll("patrocinadores");
            showScroll("patrocinadores");
            tScroll["patrocinadores"] = setInterval(function(){
                setScroll("patrocinadores");
            },10000);
        }

    });
})(jQuery);
