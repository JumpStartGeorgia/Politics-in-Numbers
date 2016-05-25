/* global $ */
/*eslint no-console: "error"*/
//= require jquery-ui/datepicker
$(document).ready(function (){
  // console.log("here");
  var finance_toggle = $("#finance_toggle"),
    donation_toggle = $("#donation_toggle"),
    filter_type = $("#filter_type"),
    is_type_donation = true,
    filter_extended = $("#filter_extended"),
    finance_category = $("#finance_category"),
    overlay = $(".overlay"),
    autocompletes = {};

  finance_toggle.click(function (event){
    is_type_donation = false;
    var p = finance_toggle.parent().parent();
    donation_toggle.parent().removeClass("active");

    if(!p.hasClass("active")) {
      p.addClass("active");
      filter_type.attr("data-type", "finance");
      filter_extended.attr("data-type", "finance");
    }

    filter_type.addClass("in-depth");
    event.stopPropagation();
  });

  donation_toggle.click(function (event){
    is_type_donation = true;
    var p = donation_toggle.parent();
    finance_toggle.parent().parent().removeClass("active");

    if(!p.hasClass("active")) {
      p.addClass("active");
      filter_type.attr("data-type", "donation");
      filter_extended.attr("data-type", "donation");
    }
    event.stopPropagation();
  });

  // filter_type.find(".forward").click(function () {
  //   var p = donation_toggle.parent();
  //   p.removeClass("active");
  //   filter_type.attr("data-type", "");
  // });

  filter_type.find(".back").click(function () {1
    filter_type.toggleClass("in-depth");
  });

  finance_category.find(".finance-category-toggle").click(function(event) {
     console.log("toggle");
    if(is_type_donation) { finance_toggle.trigger("click"); }
    var t = $(this), state = t.attr("data-state"), sub, sub_state, cat = t.attr("data-cat");
    global_click_callback = undefined;
    if(typeof state === "undefined" || state === "") {
      t.attr("data-state", "preselect");
      $(event.target).next().focus();
      global_click_callback = function() { // if clicked outside box will be reseted in preselect mode only
        t.attr("data-state", "");
      };
    }
    else if(state === "preselect") {
      sub = $(event.target);
      sub_state = sub.attr("data-sub");
      t.parent().next().find(".finance-category-toggle a").focus();
      t.attr("data-state", sub_state);
      // console.log("added", cat, sub_state);
      // TODO call filter with sub_state(all|campaign)

    }
    else if(state === "all" || state === "campaign") {
      t.find(".sub").removeClass("selected");
      t.attr("data-state", "");
      // console.log("remove", cat);
      // TODO call filter with removing this category with state option
    }
    else if(state === "simple") {
      t.attr("data-state", "simpled");
      // TODO call filter with sub_state(all|campaign)
      // console.log("added", cat);
    }
    else if(state === "simpled") {
      t.attr("data-state", "simple");

      // console.log("removed", cat);
    }
    event.preventDefault();
    event.stopPropagation();
  });

// -----------------------------------------------------------------

  filter_extended.find(".filter-toggle").click(function(){
    filter_extended.toggleClass("active");
    overlay.removeClass("hidden");
    event.stopPropagation();
  });
  filter_extended.find(".filter-close").click(function(){
    overlay.addClass("hidden");
    filter_extended.toggleClass("active");
  });
  filter_extended.find(".filter-input .toggle").click(function(){
    var t = $(this).parent();
    t.toggleClass("expanded");
  });
  function function_name (argument) {
    // body...
  }
  $(window).on("resize", function(){
    filter_extended.find(".filter-inputs").css("max-height", $(window).height() - filter_extended.find(".filter-toggle").offset().top);
  });


  function filter() {

  }

  var autocomplete_change = debounce(function(event) {
    console.log(event);

    var t = $(this), v = t.val(), p = t.parent(), ul = p.find("ul"), autocomplete_id = p.attr("data-autocomplete-id");
    if(event.type === "keyup" && event.keyCode === 40) {
      // ul.find("li:first").addClass("focus").focus();

      global_keyup_up_callback = function() {
        var tmp = ul.find("li.focus").removeClass("focus").prev();
        if(!tmp.length) { tmp = ul.find("li:last"); }
        tmp.addClass("focus").focus();
      };
      global_keyup_down_callback = function() {
        console.log("down");
        var tmp = ul.find("li.focus").removeClass("focus").next();
        if(!tmp.length) { tmp = ul.find("li:first"); }
        tmp.addClass("focus").focus();
      };
      global_keyup_down_callback();
    }
    else {
      if(v.length >= 3 && t.data("previous") !== v) {
        t.data("previous", v);
        console.log("ajax");
        $.ajax({
          url: "select/donors",
          dataType: 'json',
          data: { q: v },
          success: function(data) {
            var html = "";
            data.forEach(function(d) {
              html += "<li data-id='" + d[1] + "'" + (autocompletes.has(autocomplete_id, d[1]) ? "class='selected'" : "") + " tabindex='1'>" + d[0] + "</li>";
            });
            p.find("ul").html(html).addClass("active");
            console.log("ajax success");
          }
        });
      }
      else {
        ul.addClass("active");
      }
    }
    event.stopPropagation();
  }, 250);
  $(".autocomplete input").on("change paste keyup", autocomplete_change);
  $(".autocomplete input").on("click", function() {
    var t = $(this), v = t.val(), p = t.parent(), ul = p.find("ul");
    p.addClass("active");
    global_click_callback = function(target) {
      target = $(target);
       console.log("here", target.hasClass(".autocomplete"), target.closest(".autocomplete").length);
      if(!target.hasClass(".autocomplete") && !target.closest(".autocomplete").length) {
         console.log("inner");
        p.removeClass("active");
        global_click_callback = undefined;
        global_keyup_up_callback = undefined;
        global_keyup_down_callback = undefined;
      }
    }
    event.stopPropagation();
  });

  $(document).on("click keypress", ".autocomplete .dropdown li", function(event) {
     console.log("click keypress autocomplete name");
    if(event.type === "keypress" && event.keyCode !== 13) { return; }
    var t = $(this), dropdown = t.parent(), p = dropdown.parent(), is_selected = t.hasClass("selected");

    t.toggleClass("selected");
    var autocomplete_id = p.attr("data-autocomplete-id");
    if(is_selected) {
       console.log("is selected");
      autocompletes.pop(autocomplete_id, t.attr("data-id"));
    }
    else {
      console.log("is not selected");
      autocompletes.push(autocomplete_id, t.attr("data-id"), t.text());
    }
    // console.log(autocompletes);
    event.stopPropagation();
  });
  autocompletes.push = function(autocomplete_id, key, value) {
    if(!this.hasOwnProperty(autocomplete_id)) {
      this[autocomplete_id] = {};
    }
    if(!this[autocomplete_id].hasOwnProperty(key)) {
      $("[data-autocomplete-view='" + autocomplete_id + "']").append("<li data-id='"+key+"'>"+value+"<i class='close' title='" + gon.filter_item_close + "'></i></li>");
      this[autocomplete_id][key] = value;
    }
  };
  autocompletes.pop = function(autocomplete_id, key) {
    if(this.hasOwnProperty(autocomplete_id) && this[autocomplete_id].hasOwnProperty(key)) {
      $("[data-autocomplete-view='" + autocomplete_id + "'] li[data-id='" + key + "']").remove();
      delete this[autocomplete_id][key];
    }
  };
  autocompletes.has = function(autocomplete_id, key) {
    return this.hasOwnProperty(autocomplete_id) && this[autocomplete_id].hasOwnProperty(key);
  };
  $(document).on("click", ".list li .close", function(event) {
    var t = $(this).parent(), list = t.parent(), autocomplete_id = list.attr("data-autocomplete-view");
    $("[data-autocomplete-id='" + autocomplete_id + "'] .dropdown li[data-id='" + t.attr("data-id") + "']").toggleClass("selected");
    autocompletes.pop(autocomplete_id, t.attr("data-id"));
    event.stopPropagation();
  });

  filter_extended.find(".datepicker").datepicker();

  // dev block
    filter_extended.find(".filter-toggle").trigger("click");
    filter_extended.find(".filter-input:nth-of-type(3) .toggle").trigger("click");
});
