/*global $, chrome*/
/*eslint no-console: "allow"*/

//= require jquery
//= require jquery_ujs
//= require jquery-ui/datepicker

////////////////////////////////////////
///////  Load dependencies here  ///////

// Bootstrap Javascript
// require twitter/bootstrap/transition
// require twitter/bootstrap/alert
// require twitter/bootstrap/modal
//= require twitter/bootstrap/dropdown
// require twitter/bootstrap/scrollspy
//= require twitter/bootstrap/tab
//= require twitter/bootstrap/tooltip
// require twitter/bootstrap/popover
// require twitter/bootstrap/button
// require twitter/bootstrap/collapse
// require twitter/bootstrap/carousel
// require twitter/bootstrap/affix
//= require util
// require select2
//= require dataTables/jquery.dataTables
//= require dataTables/bootstrap/3/jquery.dataTables.bootstrap
//= require dataTables/extras/dataTables.responsive

//= require_self
////////////////////////////////////////

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
 console.log("est");

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



     // console.log("test");
     // $("input").click(function(){
     //   console.log($(this).val());
     // });
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

    //$(".datepicker").datepicker();
    $( ".datepicker.start" ).datepicker({
      //defaultDate: "+1w",
      changeMonth: true,
      changeYear: true,
      numberOfMonths: 1,
      onClose: function( selectedDate ) {
        $(".datepicker.end").datepicker( "option", "minDate", selectedDate );
      }
    });
    $( ".datepicker.end" ).datepicker({
      //defaultDate: "+1w",
      changeMonth: true,
      changeYear: true,
      numberOfMonths: 1,
      onClose: function( selectedDate ) {
        $( ".datepicker.start" ).datepicker( "option", "maxDate", selectedDate );
      }
    });

  $(".image_preview_trigger").change(function(){ readURL(this); });

  function readURL(input) {
    if (input.files && input.files[0]) {
      var reader = new FileReader();
      reader.onload = function (e) {
        $("#image_preview_reciever_" + input.id + " img").attr('src', e.target.result);
      }
      reader.readAsDataURL(input.files[0]);
    }
  }
  $(".embed_preview_trigger").change(function(e){
    $("#embed_preview_reciever_" + this.id + " iframe").attr('src', this.value);
  });

});
