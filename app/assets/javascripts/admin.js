/*global $, chrome*/
/*eslint no-console: "allow"*/

function permalink (str, locale, receiver) {
 $.ajax({
    dataType: "json",
    url: "/permalink",
    data: {"value": str, "locale" : locale},
    success:  function (data) {
       console.log(data);
      $(receiver).val(data.permalink ? data.permalink : "");
    }
  });
}


$(".permalink-trigger").on("change keyup paste click", debounce(function() {
  var t = $(this), receiver = t.attr("data-permalink-receiver");
  permalink(t.val(), receiver.substr(receiver.length - 2), receiver);
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
var datatable = null;
$(document).ready(function(){
    datatable = $('.datatable').DataTable({
      responsive: true,
      columnDefs: [
        { targets: 'sorting_disabled', orderable: false }
      ]
      // fnHeaderCallback: function() {
      //    console.log("here");
      //   return $('th.no-sort').removeClass("sorting").off("click");
      // }
    });



     console.log("test");
     $("input").click(function(){
       console.log($(this).val());
     });
    $("#toggle_type input").change(function(){
      var t = $(this), p = t.parent(), v = t.val();
      //, table = p.closest("table"),
      //rows = table.dataTable().$("tr", {"filter":"applied"});

      //rows.find("input[type='radio'][value='"+v+"'][name$='][type]']").prop("checked", true);

      var trs = $(datatable.$("tr", {"filter": "applied"}));
      trs.find("td input[type='radio'][value!='"+v+"'][name$='][type]']").prop("checked", false);
      trs.find("td input[type='radio'][value='"+v+"'][name$='][type]']").prop("checked", true); //.trigger("change");
    });

    $("#user-dropdown").click(function(){
      $(this).find(".badge-notifier").removeClass("badge-notifier");
    });
    $(".tree ul .box.inner").click(function(){ $(this).toggleClass("closed"); });
});
