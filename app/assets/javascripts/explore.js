/* global $ */
$(document).ready(function (){
   console.log("here");
  var finance_toggle = $("#finance_toggle"),
    donation_toggle = $("#donation_toggle"),
    filter_type = $("#filter_type");

  finance_toggle.click(function (event){
    var p = finance_toggle.parent();
    donation_toggle.parent().removeClass("active");

    if(!p.hasClass("active")) {
      p.addClass("active");
      filter_type.attr("data-type", "finance");
    }
    else {
      //filter_type.attr("data-type", "finance");
    }
    event.stopPropagation();
  });

  donation_toggle.click(function (event){
    var p = donation_toggle.parent();
    finance_toggle.parent().removeClass("active");

    if(!p.hasClass("active")) {
      p.addClass("active");
      filter_type.attr("data-type", "donation");
    }
    else {
      //filter_type.attr("data-type", "");
    }
    event.stopPropagation();
  });

});
