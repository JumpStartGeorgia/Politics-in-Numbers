/* global $ */
/*eslint no-console: "error"*/
// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's v2endor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
////////////////////////////////////////
//
// For turbolinks to work, these jQuery libraries must be loaded first and
// turbolinks last. Put other libraries in the marked area in the middle.
//
//= require jquery
// require jquery.turbolinks
//= require jquery_ujs

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
//= require select2
//= require dataTables/jquery.dataTables
//= require dataTables/bootstrap/3/jquery.dataTables.bootstrap
//= require dataTables/extras/dataTables.responsive
//
// require_tree .

////////////////////////////////////////

// require turbolinks
// require google-analytics-turbolinks

$(document).ready(function (){
  var nav = false;
  $(".navbar-toggle").click(function (event){
    var t = $(this).closest(".navbar-toggle-receiver"),
      state = t.hasClass("active");
    $(".navbar-toggle-receiver").removeClass("active");
    t.toggleClass("active", !state);
    nav = true;
    event.stopPropagation();
  });
  $(document).click(function (event){
    var t = $(event.target);
    //console.log(event, t.hasClass("navbar-section"), t.hasClass("active"));
    if(nav && !(t.hasClass("navbar-section") && t.hasClass("active")) && !$(this).closest(".navbar-section").length) {
      $(".navbar-toggle-receiver").removeClass("active");
    }
    if(typeof global_click_callback === "function") {
      global_click_callback(event.target);
    }
  });
});
