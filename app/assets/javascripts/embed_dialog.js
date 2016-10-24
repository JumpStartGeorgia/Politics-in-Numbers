/* global $ js gon */
/*eslint no-console: "error"*/
var embed_dialog = (function () {
  var obj = undefined,
    dgel = $("dialog#embed"),
    state = 0,
    Key = { ESC: 27 },
    prev_originator = undefined,
    sid = undefined;
  // var el: $("#embed_template"),
  // mn: $("main"),


  (function init () {
    dgel.find("> .bg").click(function () {
      obj.close();
    });
    $(document).keydown(function ( event ) {
      if (!event) {event = window.event;} // for IE compatible
      var keycode = event.keyCode || event.which; // also for cross-browser compatible
      if(keycode === Key.ESC && state === 1) {
        obj.close();
      }
    });
    $(".dialog-button").click(function () {
      // validate data is good
      // send to receiver
      obj.close();
    });
    $(window).on("resize.dialog", function () { resize(); });

    // embed dialog
    dgel.find(".iframe-sizes").change(function () {
      if(this.value === "custom") {
        dgel.find(".iframe-custom").fadeIn();
      }
      else {
        dgel.find(".iframe-custom").fadeOut();
        // var tmp = this.value.split("x");
        // dgel.find(".iframe-width").val(tmp[0]);
        // dgel.find(".iframe-height").val(tmp[1]);
      }
      iframe();
    });
    dgel.find(".iframe-custom input").change(function () {
      iframe();
    });
    dgel.find(".embed-type .toggle-group .toggle").click(function () {
      var t = $(this), tp = t.attr("data-toggle");
      t.parent().attr("data-toggle", tp);
      if(tp === "static") {
        if(typeof js.sid !== "undefined") {
          var tmp = js.esid[js.is_donation ? "d" : "f"];
          if(typeof tmp !== "undefined") {
            sid = tmp;
            iframe();
          }
          else {
            console.log("remote embed static id");
            $.ajax({
              url: gon.embed_path.replace("_id_", js.sid),
              dataType: "json",
              success: function (data) {
                if(data.hasOwnProperty("sid")) {
                  sid = data.sid;
                  js.esid[js.is_donation ? "d" : "f"] = sid;
                  iframe();
                }
              }
            });
          }
        }
        else {
          console.log("Explore page before embeding.");
        }
      }
      else {
        iframe();
      }
    });
  })();
  function resize () {
    var sec = dgel.find("section.active").first();
    sec.css({ top: $(window).height()/2 - sec.height()/2, left: $(window).width()/2 - sec.width()/2 });
  }
  function iframe (originator) {
    if(typeof originator === "undefined") {
      originator = prev_originator;
    }
    var textarea = dgel.find("section.active textarea"),
      sel = dgel.find(".iframe-sizes option:selected"),
      type = dgel.find(".embed-type .toggle-group").attr("data-toggle"),
      tmp_w, tmp_h;
    if (sel.val() === "custom") {
      tmp_w = dgel.find(".iframe-width").val();
      tmp_h = dgel.find(".iframe-height").val();
    }
    else {
      var tmp = sel.val().split("x");
      tmp_w = tmp[0];
      tmp_h = tmp[1];
    }

    var uri = textarea.attr("data-iframe-link").replace("_type_", type).replace("_id_", type === "dynamic" ? js.sid : sid);
    textarea.text("<iframe src='" + uri + "?c=" + originator + "' width='"+tmp_w+"px' height='" + tmp_h + "px' frameborder='0'></iframe>");

    prev_originator = originator;
  }

  obj = {
    open: function open (type, originator) {
      sid = undefined;
      var sec = dgel.find("section[data-type='" + type + "']");
      dgel.find("section.active").removeClass("active");
      sec.addClass("active");
      iframe(originator);
      // this.mn.attr("tabindex", 0);
      // sec.find("input, button").first().focus();
      dgel.addClass("active");
      resize();
      state = 1;
    },
    close: function close () {
      // this.mn.removeAttr("tabindex");
      dgel.find(".embed-type .toggle-group .toggle[data-toggle='dynamic']").trigger("click");
      dgel.find("section.active").removeClass("active");
      dgel.removeClass("active");
      state = 0;
    }
  };

  return obj;
})();
