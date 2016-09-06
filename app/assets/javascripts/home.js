$(document).ready(function (){
  $("body.root.index #finance_toggle").click(function (event){
    window.location = $(this).data('link');
  });

  $("body.root.index #donation_toggle").click(function (event){
    window.location = $(this).data('link');
  });
});