/*global $, chrome*/
/*eslint no-console: "allow"*/

function permalink (str, receiver) {
 $.ajax({
    dataType: "json",
    url: "/permalink",
    data: {"for_string": str},
    success:  function (data) {
      $(receiver).val(data.permalink ? data.permalink : "");
    }
  });
}


$(".permalink-trigger").on("change keyup paste click", debounce(function() {
  var t = $(this);
  permalink(t.val(), t.attr("data-permalink-receiver"));
}));


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
