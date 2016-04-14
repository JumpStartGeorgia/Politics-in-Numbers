function permalink (str) {
 $.ajax({
    dataType: "json",
    url: "/permalink",
    data: {"for_string": str},
    success:  function (data,sec) {
      console.log(data.permalink);
      // permalink to it's place
    }
  });
}
permalink("Вфошщыва ");




$( "#categories-list" ).select2({
    theme: "bootstrap",
    templateSelection: function(data, container){
       //console.log(data, container);
       return data.text;
    },
    templateResult: function(result, container){
       //console.log(result, container);
       $(container).addClass("level-" + $(result.element).attr("data-level"));
       return result.text;
    }
});
$( "#categories-list2" ).select2({
    theme: "bootstrap",
    templateSelection: function(data, container){
       //console.log(data, container);
       return data.text;
    },
    templateResult: function(result, container){
       //console.log(result, container);
       $(container).addClass("level-" + $(result.element).attr("data-level"));
       return result.text;
    }
});
