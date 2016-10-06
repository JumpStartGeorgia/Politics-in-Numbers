/* global $ */
/*eslint no-console: "error"*/
//= require jquery-ui/datepicker
//= require dataTables.pagination.js
//= require jquery-ui/tooltip
var dn;
$(document).ready(function (){
  // console.log("explore ready");
  var js = {
      cache: {}
    },
    w = 0,
    h = 0,
    filter_el = $(".filter"),
    filter_submit = $("#filter_submit"),
    finance_toggle = $(".filter-type-toggle[data-type='finance']"),
    donation_toggle = $(".filter-type-toggle[data-type='donation']"),
    view_content = $(".view-content"),
    is_type_donation = true,
    loader = $(".view-loader"),
    view_action = $("#view_action"),
    view_table = $("#view_table"),
    view_table_object = undefined,
    finance_datatable,
    autocomplete = {
      push: function(autocomplete_id, key, value) {
        if(!this.hasOwnProperty(autocomplete_id)) {
          this[autocomplete_id] = {};
        }
        if(!this[autocomplete_id].hasOwnProperty(key)) {
          $("[data-autocomplete-view='" + autocomplete_id + "']").append(li(key, value));
          this[autocomplete_id][key] = value;
        }
        //console.log(autocomplete);
      },
      pop: function(autocomplete_id, key) {
        if(this.hasOwnProperty(autocomplete_id) && this[autocomplete_id].hasOwnProperty(key)) {
          $("[data-autocomplete-view='" + autocomplete_id + "'] li[data-id='" + key + "']").remove();
          $("[data-autocomplete-id='" + autocomplete_id + "'] .dropdown li .item[data-id='" + key + "']").removeClass("selected");
          delete this[autocomplete_id][key];
        }
      },
      clear: function(autocomplete_id) {
        if(this.hasOwnProperty(autocomplete_id)) {
          $("[data-autocomplete-view='" + autocomplete_id + "'] li").remove();
          $("[data-autocomplete-id='" + autocomplete_id + "'] .dropdown li .item").removeClass("selected");
          delete this[autocomplete_id];
        }
      },
      has: function(autocomplete_id, key) {
        return this.hasOwnProperty(autocomplete_id) && this[autocomplete_id].hasOwnProperty(key);
      },
      onchange: debounce(function(event) {
        var t = $(this), v = t.val(), p = t.parent(), ul = p.find("ul"), autocomplete_id = p.attr("data-autocomplete-id");
        if(event.type === "keyup" && event.keyCode === 40) {
          // ul.find("li:first").addClass("focus").focus();

          global_keyup_up_callback = function() {
            var tmp = ul.find("li.focus").removeClass("focus").prev();
            if(!tmp.length) { tmp = ul.find("li:last"); }
            tmp.addClass("focus").focus();
          };
          global_keyup_down_callback = function() {
            //console.log("down");
            var tmp = ul.find("li.focus").removeClass("focus").next();
            if(!tmp.length) { tmp = ul.find("li:first"); }
            tmp.addClass("focus").focus();
          };
          global_keyup_down_callback();
        }
        else {
          if(v.length >= 3 && t.data("previous") !== v) {
            t.data("previous", v);
            if(p.is("[data-local]")) {
              ul.find("li").hide();
              var regex = new RegExp(".*" + v + ".*", "i"),
                local = p.attr("data-local"),
                multilevel = finance.categories.indexOf(local) !== -1,
                list = multilevel ? gon.category_lists[local] : gon[local + "_list"], to_show = [];
              if(multilevel) {
                list.forEach(function(d) {
                  if(d[1].match(regex) !== null) {
                    to_show.push(d[0]);
                    if(d[2] !== -1) {
                      var d2 = d[2];
                      while(d2 !== -1) {
                        to_show.push(d2);
                        d2 = list.filter(function (ll) { return ll[0] === d2; })[0][2];
                      }
                    }
                    to_show.forEach(function(ts) {
                      ul.find("li .item[data-id='" + ts + "']").parent().show();
                    });
                  }
                });
              }
              else {
                list.forEach(function(d) {
                  if((d[1] + (d.length === 3 ? d[2] : "")).match(regex) !== null) {
                    to_show.push(d[0]);
                  }
                });
                to_show.forEach(function(ts) {
                  ul.find("li .item[data-id='" + ts + "']").parent().show();
                });
              }
            }
            else {
              console.log("ajax");
              $.ajax({
                url: p.attr("data-url"),
                dataType: 'json',
                data: { q: v },
                success: function(data) {
                  var html = "";
                  console.log("back", data);
                  data.forEach(function(d) {
                    html += "<li data-id='" + d[1] + "'" + (autocomplete.has(autocomplete_id, d[1]) ? "class='selected'" : "") + " tabindex='1'>" + d[0] + "</li>";
                  });
                  p.find("ul").html(html).addClass("active");
                  //console.log("ajax success");
                }
              });
            }
          }
          else {
            ul.addClass("active");
          }
        }
        event.stopPropagation();
      }, 250),
      // search_tree: function () {}
      bind: function() {
        $(".autocomplete[data-source]").each(function() {
          var t = $(this), source = t.attr("data-source"), html = "";
          if(gon.hasOwnProperty(source) && Array.isArray(gon[source])) {
            gon[source].forEach(function(d) {
              html += "<li><div class=\"item\" data-id=" + d[0] + ">" + d[1] + "</div></li>";
            });
            t.find(".dropdown").html(html);
          }
        });
        $(".autocomplete input").on("change paste keyup", this.onchange);
        $(".autocomplete input").on("click", function() {
          //console.log("here");
          var t = $(this), v = t.val(), p = t.parent(), ul = p.find("ul");
          p.addClass("active");
          global_click_callback = function(target) {
            target = $(target);
             //console.log("here", target.hasClass(".autocomplete"), target.closest(".autocomplete").length);
            if(!target.hasClass(".autocomplete") && !target.closest(".autocomplete").length) {
               //console.log("inner");
              p.removeClass("active");
              global_click_callback = undefined;
              global_keyup_up_callback = undefined;
              global_keyup_down_callback = undefined;
            }
          }
          event.stopPropagation();
        });

        $(document).on("click keypress", ".autocomplete .dropdown li .item", function(event) {
          // console.log("click keypress autocomplete name");
          if(event.type === "keypress" && event.keyCode !== 13) { return; }
          var t = $(this), dropdown = t.closest(".dropdown"), p = dropdown.parent(), is_selected = t.hasClass("selected");

          t.toggleClass("selected");
          var autocomplete_id = p.attr("data-autocomplete-id");
          if(is_selected) {
             //console.log("is selected");
            autocomplete.pop(autocomplete_id, t.attr("data-id"));
          }
          else {
            //console.log("is not selected");
            autocomplete.push(autocomplete_id, t.attr("data-id"), t.text());
          }
          // console.log(autocomplete);
          event.stopPropagation();
        });
        $(document).on("click keypress", ".autocomplete .dropdown li .tree-toggle", function(event) {
          if(event.type === "keypress" && event.keyCode !== 13) { return; }
          $(this).parent().toggleClass("expanded");
          event.stopPropagation();
        });


        $(document).on("click", "[data-type='autocomplete'] .list li .close", function(event) {
          var t = $(this).parent(), list = t.parent(), autocomplete_id = list.attr("data-autocomplete-view");
          $("[data-autocomplete-id='" + autocomplete_id + "'] .dropdown li[data-id='" + t.attr("data-id") + "'] .item").toggleClass("selected");
          autocomplete.pop(autocomplete_id, t.attr("data-id"));
          event.stopPropagation();
        });
      }
    },
    donation = {
      types: {
        period: "period",
      },
      download: undefined,
      elem: {
        period: {
          from: $("#donation_period_from"),
          to: $("#donation_period_to")
        }
      },
      data: {},
      get: function() {
        var t = this, tp, tmp, tmp_v, tmp_d, tmp_o, lnk;
        t.data = {};
        Object.keys(this.elem).forEach(function(el){
          var is_elem = ["period"].indexOf(el) == -1;

          (is_elem ? [t.elem[el]] : Object.keys(t.elem[el]).map(function(m){ return t.elem[el][m]; })).forEach(function(elem, elem_i){
            tmp = $(elem);
            tp = tmp.attr("data-type");
            if(tp === "period") {
              tmp_v = tmp.datepicker('getDate');
              tmp_d = t.data.hasOwnProperty(el) ? t.data[el] : [-1, -1];
              if(isDate(tmp_v)) {
                tmp_d[elem_i] = tmp_v.getTime();
              }
              if(tmp_d.toString() === [-1, -1].toString()) {
                delete t.data[el];
              }
              else {
                t.data[el] = tmp_d;
              }
            }
          });
        });
        return Object.keys(t.data).length ? t.data : { "all": true };
      },
      set_by_url: function() {
        var t = this, tmp, tp, v, p, el;
        // console.log("set_by_url donation", gon.donation_params);
        if(gon.donation_params) {
          Object.keys(gon.donation_params).forEach(function(k) {
            if(k == "filter" || !t.types.hasOwnProperty(k)) return;
              el = t.elem[k];
              tp = t.types[k];
              v = gon.donation_params[k];

            if(tp === "period") {
              el.from.datepicker('setDate', new Date(+v[0]));
              el.to.datepicker('setDate', new Date(+v[1]));
              tmp = formatRange([el.from.datepicker("getDate").format(gon.date_format), el.to.datepicker("getDate").format(gon.date_format)]);
              create_list_item(el.from.parent().parent().find(".list"), tmp, tmp);
            }
          });
        }
      },
      reset: function() {
        $(".filter-inputs[data-type='donation'] .filter-input").each(function(i,d) {
          var t = $(this);
            field = t.attr("data-field"),
            type = t.attr("data-type");
             list = t.find(".list");

            if(type === "period") {
              t.find(".input-group input[type='text'].datepicker").datepicker('setDate', null);
            }
            list.empty();
            event.stopPropagation();
        });
      },
      id: function(v) {
        var period = [-1, -1], amount = [-1, -1];
        if(v.hasOwnProperty("period")) {
          period = v.period;
        }
        //console.log(["d", v.donor, period.join(";"), amount.join(";"), v.party, v.monetary,v.multiple].join(";"));
        return CryptoJS.MD5(["d", period.join(";")].join(";")).toString();
      },
      url: function(v) {
        var t = this, url = "?", params = [], tmp;

        Object.keys(this.elem).forEach(function(el){
          if(v.hasOwnProperty(el)) {
            tmp = v[el];
            params.push(el + "=" + tmp);
          }
        });
        window.history.pushState(v, null, window.location.pathname + "?filter=donation" + (params.length ? ("&" + params.join("&")) : ""));
        t.download = window.location.pathname + "?filter=donation&" + (params.length ? (params.join("&") + "&") : "") + "format=csv";
      }
    },
    finance = {
      types: {
        party: "autocomplete",
        period: "period_mix"
      },
      download: undefined,
      elem: {
        party: $("#finance_party"),
        period: $("#finance_period")
      },
      data: {},
      get: function() {
        var t = this, tp, tmp, tmp_v, tmp_d, lnk;
        t.data = {};
        Object.keys(this.elem).forEach(function(el){
          var is_elem = [].indexOf(el) == -1;
          (is_elem ? [t.elem[el]] : Object.keys(t.elem[el]).map(function(m){ return t.elem[el][m]; })).forEach(function(elem, elem_i){
            tmp = $(elem);
            tp = tmp.attr("data-type");
            if(tp === "autocomplete") {
              lnk = tmp.attr("data-autocomplete-view");
              if(autocomplete.hasOwnProperty(lnk)) {
                t.data[el] = Object.keys(autocomplete[lnk]);
              }
            }
            else if(tp === "period_mix") {
              tmp_d = tmp.find("li[data-id]");
              tmp_v = [];
              if(tmp_d.length) {
                tmp_d.each(function(){ tmp_v.push(this.dataset.id); });
                t.data[el] = tmp_v;
              }
            }
            else {
              console.log("Type is not specified", t.elem[el]);
            }
          });
        });
        return Object.keys(t.data).length ? t.data : { "all": true };
      },
      set_by_url: function() {
        var t = this, tmp, tp, v, p, el;
        // console.log("set_by_url finance", gon.finance_params);
        if(gon.finance_params) {
          Object.keys(gon.finance_params).forEach(function(k) {
            if(k == "filter" || !t.types.hasOwnProperty(k)) return;
              el = t.elem[k];
              tp = t.types[k];
              v = gon.finance_params[k];

            if(tp === "autocomplete") {
              p = el.parent();
              Object.keys(v).forEach(function(kk){
                var fld = p.attr("data-field"), tmp = fld, fl = false;
                if(t.categories.indexOf(fld) !== -1) { fl = true; tmp = "category"; }
                 //console.log("set by url",kk,v,fld,fl,tmp);
                if(gon.main_categories_ids.indexOf(v[kk]) === -1) {
                  list = fl ? gon.category_lists[fld] : gon[tmp + "_list"];
                  autocomplete.push(p.find(".autocomplete[data-autocomplete-id]").attr("data-autocomplete-id"), v[kk], list.filter(function(d) { return d[0] == v[kk]; })[0][1]);
                }
                if(fl) { emulate_category_click(fld); }
              });
            }
            else if(tp === "period_mix") {
              p = el.parent();
              var group = p.find(".input-group .input-checkbox-group"),
                group_list = group.find("li input[value='" + v[0] + "']").parent().parent();
                group_type = group_list.attr("data-type");

              p.find(".input-group .input-radio-group input[value='" + group_type + "']").prop("checked", true);
              group.find("ul").addClass("hidden");
              v.forEach(function(d){
                group.find("li input[value='" + d + "']").prop("checked", true);
                el.append(li(d, gon.period_list.filter(function(f){ return f[0] == d; })[0][1]));
              });
              group_list.removeClass("hidden");
            }
          });
        }
      },
      reset: function() {
        $(".filter-inputs[data-type='finance'] .filter-input").each(function(i,d) {
          var t = $(this);
            field = t.attr("data-field"),
            type = t.attr("data-type");
            list = t.find(".list");

            if(type === "autocomplete") {
              autocomplete.clear(t.find(".autocomplete[data-autocomplete-id]").attr("data-autocomplete-id"));
              if(typeof global_click_callback === "function") { global_click_callback(); }
            }
            else if(type === "period_mix") {
              t.find(".input-group .input-radio-group input:first-of-type").prop("checked", true);
              var group = t.find(".input-group .input-checkbox-group");
              group.find("input[type='checkbox']:checked").prop("checked", false);
              group.find("ul[data-type='annual']").removeClass("hidden");
              group.find("ul[data-type='campaign']").addClass("hidden");
            }
            list.empty();
            event.stopPropagation();
        });
      },
      id: function(v) { return CryptoJS.MD5(["f", v.party, v.period].join(";")).toString(); },
      url: function(v) {
        var t = this, url = "?", params = [], tmp;
        // console.log(v);
        Object.keys(this.elem).forEach(function(el){
          if(v.hasOwnProperty(el)) {
            tmp = v[el];
            if(Array.isArray(tmp)) {
              tmp.forEach(function(r){
                params.push(el + "[]=" + r);
              });
            }
            else {
              params.push(el + "=" + tmp);
            }
          }
        });
        window.history.pushState(v, null, window.location.pathname + "?filter=finance" + (params.length ? ("&" + params.join("&")) : ""));
        t.download = window.location.pathname + "?filter=finance&" + (params.length ? (params.join("&") + "&") : "") + "format=csv";
      }
    };

  finance_toggle.click(function (event){
    var p = finance_toggle.closest(".filter").attr("data-type", "finance");
    is_type_donation = false;
    event.stopPropagation();
  });

  donation_toggle.click(function (event){
    var p = finance_toggle.closest(".filter").attr("data-type", "donation");
    is_type_donation = true;
    event.stopPropagation();
  });



// -----------------------------------------------------------------



  function create_list_item(list, text, vbool) {
    list.html(vbool ? "<span>" + text + "<i class='close' title='" + gon.filter_item_close + "'></i></span>" : "").toggleClass("hidden", !vbool);
  }
  function li(id, text) {
    return "<li data-id='"+id+"'>"+text+"<i class='close' title='" + gon.filter_item_close + "'></i></li>";
  }
  function resize() {
    w = $(window).width();
    h = $(window).height();
  }

  function bind() {
    window.onpopstate = function(event) {
       //console.log("onpopstate location: " + window.location + ", state: " + JSON.stringify(event.state));
    };
    filter_el.find(".filter-toggle, .filter-header .close").click(function(){
      filter_el.toggleClass("active");
    });
    filter_el.find(".filter-input .toggle").click(function(){
      var t = $(this).parent(),
        field = t.attr("data-field"),
        type = t.attr("data-type"),
        html = "",
        list = t.find(".list"),
        tmp, tmp2,
        state = t.hasClass("expanded");

      if(state) {
        if(type === "period") {
          tmp = [];
          t.find(".input-group input[type='text'].datepicker").each(function(i, d){
            tmp2 = $(d).datepicker("getDate");
            tmp.push(tmp2 ? tmp2.format(gon.date_format) : null);
          });
          tmp = formatRange(tmp);
          create_list_item(list, tmp, tmp);
        }
        else if(type === "range") {
          tmp = [];
          t.find(".input-group input[type='number']").each(function(i, d){
            tmp2 = $(d).val();
            tmp.push(tmp2 !== "" ? tmp2 : null);

          });
          tmp = formatRange(tmp);
          create_list_item(list, tmp, tmp);
        }
        else if(type === "radio") {
          tmp = t.find(".input-group input[type='radio']:checked");
          create_list_item(list, tmp.next().text(), tmp.length);
        }
        else if(type === "checkbox") {
          tmp = t.find(".input-group input[type='checkbox']:checked");
          create_list_item(list, tmp.next().text(), tmp.length);
        }
        // else if(type === "period_mix") {
          // list.empty();
          // tmp = t.find(".input-radio-group input:checked").val();
          // t.find(".input-checkbox-group ul[data-type='" + tmp + "'] input:checked").each(function(i, d){
          //   list.append("<li data-id='" + d.value + "'>" + $(d).parent().find("label").text() + "<i class='close' title='" + gon.filter_item_close + "'></i></li>");
          // });
          // list.removeClass("hidden");
        // }
      }
      else {
        // if(type === "period_mix" || type === "radio") {
        //   list.addClass("hidden");
        // }
      }
      t.toggleClass("expanded", !state);
    });
    filter_el.find(".filter-input button.clear").click(function () {
      autocomplete.clear($(this).parent().attr("data-autocomplete-id"));
    });
    $(window).on("resize", function(){
      resize();
      filter_el.find(".filter-inputs").css("max-height", $(window).height() - filter_el.find(".filter-toggle").offset().top);
    });
    resize();

    donation.elem.period.from.datepicker({
      firstDay: 1,
      changeMonth: true,
      changeYear: true,
      dateFormat: gon.date_format,
      onClose: function( selectedDate ) {
        donation.elem.period.to.datepicker( "option", "minDate", selectedDate );
      }
    });
    donation.elem.period.to.datepicker({
      firstDay: 1,
      changeMonth: true,
      changeYear: true,
      dateFormat: gon.date_format,
      onClose: function( selectedDate ) {
        donation.elem.period.from.datepicker( "option", "maxDate", selectedDate );
      }
    });

    $("#donation_period_campaigns a").click(function(){
      var t = $(this), v = t.attr("data-value").split(";");
      donation.elem.period.from.datepicker('setDate', new Date(v[0]));
      donation.elem.period.to.datepicker('setDate', new Date(v[1]));
    });
    $(document).on("click", ".list > span .close, .list > li .close", function(event) {
      var t = $(this);
        p = t.closest(".filter-input"),
        field = p.attr("data-field"),
        type = p.attr("data-type"),
        li_span = t.parent();


      if(type === "period") {
        p.find(".input-group input[type='text'].datepicker").datepicker('setDate', null);
      }
      else if(type === "period_mix") {
        p.find(".input-group .input-checkbox-group input[type='checkbox'][value='" + li_span.attr("data-id") + "']:checked").prop("checked", false);
      }

      if(type !== "autocomplete") {
        li_span.remove();
      }
      event.stopPropagation();
    });
    $("#filter_reset").click(function(){
      if(is_type_donation) {
        donation.reset();
      }
      else {
        finance.reset();
      }
    });
    filter_submit.click(function(){ filter(); });


    // $(".download_list a").click(function(){
    //   var t = $(this), action = t.attr("data-type"), li = t.parent(),
    //     ul = li.parent(), source_type = ul.attr("data-type"),
    //     source = "#" + ul.attr("data-object") + "_" + source_type;

    //   export_object(source, source_type, action);
    // });


    autocomplete.bind();

    $(document).on("click", ".filter-input[data-type='period_mix'] .input-radio-group input + label", function(event) {
      var t = $(this), tp = t.attr("data-type"), filter_input = t.closest(".filter-input"),
        group = filter_input.find(".input-checkbox-group"), list = filter_input.find("> ul.list");
      list.empty();

      group.find("ul[data-type]").addClass("hidden");
      group.find("ul[data-type='" + tp + "']").removeClass("hidden");
      group.find("ul[data-type='" + tp + "'] input:checked").each(function(i, d){
        var d = $(d), p = d.parent(), text = p.find("label").text(), id = d.val();
        list.append(li(id,text));
      });
    });
    $(document).on("click", ".filter-input[data-type='period_mix'] .input-checkbox-group input + label", function(event) {
      var t = $(this), p = t.parent(), input = p.find("input"), text = t.text(), id = input.val(),
        list = p.closest(".filter-input").find("> ul.list");
      if(input.is(":checked")) {
        list.find("li[data-id='" + id + "']").remove();
      }
      else {
        list.append(li(id,text));
      }

    });

    // bind finance view_as buttons click event
    // $(".pane[data-type='finance'] .actions .left > div[data-view-toggle]").on("click", function() {
    //   $(".pane[data-type='finance']").attr("data-view-current", $(this).attr("data-view-toggle"));
    //   $(".pane[data-type='finance'] .actions .download_list").attr("data-type", $(this).attr("data-view-toggle"));
    // });
    $(document).on("click", "#download_toggle_all", function () {
      console.log("clicked all");
      var t = $(this), state = t.is(":checked");
      console.log(state, view_table_object.$("tr", {"filter": "applied"}).find("td input[type='checkbox']"));
      $(view_table_object.$("tr", {"filter": "applied"}))
        .find("td input[type='checkbox'] + label")
        .trigger("click");
      t.next("label").trigger("click");
    });
    $(document).on("click", "#download_button", function () {
      console.log("clicked to download");
      // var t = $(this), state = t.is(":checked");
      // console.log(state, view_table_object.$("tr", {"filter": "applied"}).find("td input[type='checkbox']"));
      // $(view_table_object.$("tr", {"filter": "applied"}))
      //   .find("td input[type='checkbox'] + label")
      //   .trigger("click");
      // t.next("label").trigger("click");
    });

  }

  function filter() {
    loader.fadeIn();
    //console.log("start filter", is_type_donation);
    var filters = {},
      remote_required = false, tmp, cacher_id, donation_id, finance_id;
      console.log(gon.gonned);
    if(gon.gonned) {
      donation.set_by_url();

      tmp = donation.get();
      donation_id = donation.id(tmp);

      js.cache[donation_id] = gon.donation_data;

      filter_callback(js.cache[donation_id], "donation");


      finance.set_by_url();
      tmp = finance.get();
      if(tmp === null) { return; }
      finance_id = finance.id(tmp);

      js.cache[finance_id] = gon.finance_data;

      filter_callback(js.cache[finance_id], "finance");

      gon.gonned = false;
    } else {
      if(is_type_donation) {

        tmp = donation.get();
        donation_id = donation.id(tmp);

        donation.url(tmp);

        console.log(tmp,donation_id, "-----------");
        if(!js.cache.hasOwnProperty(donation_id)) {
          filters["donation"] = tmp;
          remote_required = true;
        }
        else {
          filter_callback(js.cache[donation_id], "donation");
        }
      }
      else {

        tmp = finance.get();
        if(tmp === null) { return; }
        finance_id = finance.id(tmp);

        finance.url(tmp);

        if(!js.cache.hasOwnProperty(finance_id)) {
          filters["finance"] = tmp;
          remote_required = true;
        }
        else {
          filter_callback(js.cache[finance_id], "finance");
        }
      }


      console.log(filters);
      if(remote_required) {
        $.ajax({
          url: "download_filter",
          dataType: 'json',
          data: filters,
          success: function(data) {
            console.log("remote", data);
            if(data.hasOwnProperty("donation")) { filter_callback(js.cache[donation_id] = data.donation, "donation"); }
            if(data.hasOwnProperty("finance")) { filter_callback(js.cache[finance_id] = data.finance, "finance"); }
          }
        });
      }
    }
  }
  function filter_callback(data, partial) {
    console.log("filter_callback", data);
    var is_data_ok = typeof data !== "undefined";
    $(".view").toggleClass("not-found", !is_data_ok);
    if(is_data_ok) {
      render_table(partial, data.table, data.size);
    }
    loader.fadeOut();
  }

  function render_table(type, table, size) {
    // console.log("table data", table);
    if(type === "donation") {
      //view_content.html("new tab");
      //var prev = undefined, alt_color = true,
        view_table_object = view_content.find("table").DataTable({
          language: { searchPlaceholder: gon.search },
          responsive: true,
          destroy: true,
          order: [],
          "aaData": table.data,
          "aoColumns": table.header.map(function(m,i) {
            return {
              "title": (i === 0 ? "<input id='download_toggle_all' type='checkbox' checked><label for='download_toggle_all'><span></span></label>" : m),
              "sClass": table.classes[i],
              "bSortable": (i === 0 ? false : true),
              "sWidth": (i === 0 ? "10px" : undefined)
            };
          }),
          "info": false,
          dom: "<\"download-button\"><\"download-size\"><\"DataTables_Table_0_right\"fl>trp",
          createdRow: function ( row, data, index ) {
            console.log(data);
            if(index === 0) {
              $('td', row).eq(0).html("<input id='file' type='checkbox'" + (data[0] === 1 ? " checked" : "") + "><label for='file'><span></span></label>");
            }
            // if(data[2] !== prev) {
            //   alt_color = !alt_color;
            // }
            // if(alt_color) {
            //   $(row).addClass('alt');
            // }
            // prev = data[2];
          }
        });
        $("div.download-button").html("<button type='button'>" + gon.download + "</button>").attr("id", "download_button");
        $("div.download-size").text(size).attr("id", "download_size");

      // dt.on("draw", function (e, settings) {
      //   if(settings.aaSorting.length) {
      //     $(this).toggleClass("highlighted", settings.aaSorting[0][0] === 1);
      //   }
      // });
    }
    else if(type === "finance") {
      // var table_html = "<thead>", colspan = 0, tmp, klass;
      // table.header.forEach(function(row, row_i) {

      //   table_html += "<tr>";
      //   row.forEach(function(col, col_i) {
      //     if(col === null) {
      //       ++colspan;
      //     }
      //     else {
      //       tmp = "";
      //       klass = table.header_classes[row_i][col_i];
      //       klass = klass !== null ? " class='" + klass + "'" : "";

      //       if(colspan) {
      //         tmp = " colspan='" + (colspan+1) + "'";
      //         colspan = 0;
      //       }
      //       table_html += "<th" + klass + tmp +">" + col + "</th>";
      //     }
      //   });
      //   table_html += "</tr>";
      // });
      // table_html += "</thead><tbody>";


      // table.data.forEach(function(row, row_i) {
      //   table_html += "<tr>";
      //   row.forEach(function(col, col_i) {
      //     klass = table.classes[col_i];
      //     klass = klass !== null ? " class='" + klass + "'" : "";
      //     table_html += "<td" + klass + ">" + col + "</th>";
      //   });
      //   table_html += "</td>";
      // });
      // table_html += "</tbody>";

      // if(typeof finance_datatable !== "undefined") {
      //   finance_datatable.destroy();
      // }
      // finance_table.html(table_html);
      // finance_datatable = finance_table.DataTable({
      //   destroy: true,
      //   responsive: true,
      //   //"aaData": table.data,
      //   // "aoColumns": table.header.map(function(m,i) {
      //   //   return { "title": m, "sClass": table.classes[i], "visible": i != 0 };
      //   // }),
      //   "info": false,
      //   dom: "Bfltrp"
      // });
    }

  }

  (function init() {
    bind();
    is_type_donation = gon.gonned_type === "donation";

    filter();
  })();
});

