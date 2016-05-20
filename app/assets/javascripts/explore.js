/* global $ */
/*eslint no-console: "error"*/
$(document).ready(function (){
  // console.log("here");
  var finance_toggle = $("#finance_toggle"),
    donation_toggle = $("#donation_toggle"),
    filter_type = $("#filter_type"),
    finance_category = $("#finance_category");

  finance_toggle.click(function (event){
    var p = finance_toggle.parent().parent();
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
    finance_toggle.parent().parent().removeClass("active");

    if(!p.hasClass("active")) {
      p.addClass("active");
      filter_type.attr("data-type", "donation");
    }
    else {
      //filter_type.attr("data-type", "");
    }
    event.stopPropagation();
  });

  filter_type.find(".forward").click(function () {
    var p = donation_toggle.parent();
    p.removeClass("active");
    filter_type.attr("data-type", "");
  });

  filter_type.find(".back").click(function () {
    var p = finance_toggle.parent().parent();
    p.removeClass("active");
    filter_type.attr("data-type", "");
  });

  finance_category.find(".finance-category-toggle").click(function(event) {
    var t = $(this), state = t.attr("data-state"), sub, sub_state, cat = t.attr("data-cat");
    global_click_callback = undefined;
    if(typeof state === "undefined" || state === "") {
      t.attr("data-state", "preselect");
      global_click_callback = function() { // if clicked outside box will be reseted in preselect mode only
        t.attr("data-state", "");
      };
    }
    else if(state === "preselect") {
      sub = $(event.target);
      sub_state = sub.attr("data-sub");
      sub.addClass("selected");
      t.attr("data-state", sub_state);
      console.log("added", cat, sub_state);
      // TODO call filter with sub_state(all|campaign)

    }
    else if(state === "all" || state === "campaign") {
      t.find(".sub").removeClass("selected");
      t.attr("data-state", "");
      console.log("remove", cat);
      // TODO call filter with removing this category with state option
    }
    else if(state === "simple") {
      t.attr("data-state", "simpled");
      // TODO call filter with sub_state(all|campaign)
      console.log("added", cat);
    }
    else if(state === "simpled") {
      t.attr("data-state", "simple");
      console.log("removed", cat);
    }
    event.stopPropagation();
  });

});
