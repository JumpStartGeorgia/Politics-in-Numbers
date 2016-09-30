/* global $ */
/*eslint no-console: "error"*/
//= require jquery-ui/datepicker
//= require dataTables.pagination.js
var dn;
$(document).ready(function (){
  // console.log("explore ready");
  var js = {
      cache: {}
    },
    explore = $("#explore"),
    explore_button = $("#explore_button"),
    finance_toggle = $("#finance_toggle"),
    donation_toggle = $("#donation_toggle"),
    filter_type = $("#filter_type"),
    is_type_donation = true,
    filter_extended = $("#filter_extended"),
    finance_category = $("#finance_category"),
    content = $("#content"),
    overlay = $(".overlay"),
    donation_total_amount = $("#donation_total_amount span"),
    donation_total_donations = $("#donation_total_donations span"),
    donation_table = $("#donation_table table"),
    finance_table = $("#finance_table table"),
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
        donor: "autocomplete",
        period: "period",
        amount: "range",
        party: "autocomplete",
        monetary: "radio",
        multiple: "checkbox",
        nature: "radio"
      },
      download: $("#donation_csv_download"),
      elem: {
        donor: $("#donation_donor"),
        period: {
          from: $("#donation_period_from"),
          to: $("#donation_period_to")
        },
        amount: {
          from: $("#donation_amount_from"),
          to: $("#donation_amount_to")
        },
        party: $("#donation_party"),
        monetary: {
          yes: $("#donation_monetary_yes"),
          no: $("#donation_monetary_no")
        },
        multiple: $("#donation_multiple_yes"),
        nature: {
          individual: $("#donor_nature_individual"),
          organization: $("#donor_nature_organization")
        }
      },
      data: {},
      get: function() {
        var t = this, tp, tmp, tmp_v, tmp_d, tmp_o, lnk;
        t.data = {};
        Object.keys(this.elem).forEach(function(el){
          var is_elem = ["period", "amount", "monetary", "nature"].indexOf(el) == -1;

          (is_elem ? [t.elem[el]] : Object.keys(t.elem[el]).map(function(m){ return t.elem[el][m]; })).forEach(function(elem, elem_i){
            tmp = $(elem);
            tp = tmp.attr("data-type");
            if(tp === "autocomplete") {
              lnk = tmp.attr("data-autocomplete-view");
              if(autocomplete.hasOwnProperty(lnk)) {
                t.data[el] = Object.keys(autocomplete[lnk]);
              }
            }
            else if(tp === "period") {
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
            else if(tp === "range") {
              tmp_v = tmp.val();
              tmp_d = t.data.hasOwnProperty(el) ? t.data[el] : [-1, -1];
              if(isNumber(tmp_v)) {
                tmp_d[elem_i] = tmp_v;
              }
              if(tmp_d.toString() === [-1, -1].toString()) {
                delete t.data[el];
              }
              else {
                t.data[el] = tmp_d;
              }
            }
            else if(tp === "radio") {
              if(tmp.is(":checked")) {
                t.data[el] = tmp.val();
              }
            }
            else if(tp === "checkbox") {
              if(tmp.is(":checked")) {
                t.data[el] = tmp.val();
              }
            }
            else {
              //console.log("Type is not specified", t.elem[el]);
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

            if(tp === "autocomplete") {
              p = el.parent();
              Object.keys(v).forEach(function(kk){
                var local = p.attr("data-field"),
                  is_category = finance.categories.indexOf(local) !== -1,
                  list = is_category ? gon.category_lists[local] : gon[local + "_list"];

                autocomplete.push(p.find(".autocomplete[data-autocomplete-id]").attr("data-autocomplete-id"), v[kk], list.filter(function(d) { return d[0] == v[kk]; })[0][1]);
              });
            }
            else if(tp === "period") {
              el.from.datepicker('setDate', new Date(+v[0]));
              el.to.datepicker('setDate', new Date(+v[1]));
              tmp = formatRange([el.from.datepicker("getDate").format(gon.date_format), el.to.datepicker("getDate").format(gon.date_format)]);
              create_list_item(el.from.parent().parent().find(".list"), tmp, tmp);
            }
            else if(tp === "range") {
              el.from.val(+v[0]);
              el.to.val(+v[1]);
              tmp = formatRange(v);
              create_list_item(el.from.parent().parent().find(".list"), tmp, tmp);
            }
            else if(tp === "radio") {
              el = el[Object.keys(el)[0]];
              p = el.closest(".filter-input");
              tmp = p.find(".input-group input[type='radio'][value='" + v + "']").prop("checked", true);
              create_list_item(p.find(".list"), tmp.next().text(), tmp.length);
            }
            else if(tp === "checkbox") {
              tmp = el.prop("checked", el.val() === v ? true : false);
              create_list_item(el.closest(".filter-input").find(".list"), tmp.next().text(), tmp.length);
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

            if(type === "autocomplete") {
              autocomplete.clear(t.find(".autocomplete[data-autocomplete-id]").attr("data-autocomplete-id"));
              if(typeof global_click_callback === "function") { global_click_callback(); }
            }
            else if(type === "period") {
              t.find(".input-group input[type='text'].datepicker").datepicker('setDate', null);
            }
            else if(type === "range") {
              t.find(".input-group input[type='number']").val(null);
            }
            else if(type === "radio") {
              t.find(".input-group input[type='radio']:checked").prop("checked", false);
            }
            else if(type === "checkbox") {
              t.find(".input-group input[type='checkbox']:checked").prop("checked", false);
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
        if(v.hasOwnProperty("amount")) {
          amount = v.amount;
        }
        //console.log(["d", v.donor, period.join(";"), amount.join(";"), v.party, v.monetary,v.multiple].join(";"));
        return CryptoJS.MD5(["d", v.donor, period.join(";"), amount.join(";"), v.party, v.monetary, v.multiple, v.nature].join(";")).toString();
      },
      url: function(v) {
        var t = this, url = "?", params = [], tmp;

        Object.keys(this.elem).forEach(function(el){
          if(v.hasOwnProperty(el)) {
            tmp = v[el];
            if(el !== "monetary" && el !== "multiple" && el !== "nature" && Array.isArray(tmp)) {
              tmp.forEach(function(r){
                params.push(el + "[]=" + r);
              });
            }
            else {
              params.push(el + "=" + tmp);
            }
          }
        });
        window.history.pushState(v, null, window.location.pathname + "?filter=donation" + (params.length ? ("&" + params.join("&")) : ""));
        t.download.attr("href", window.location.pathname + "?filter=donation&" + (params.length ? (params.join("&") + "&") : "") + "format=csv")
      }
    },
    finance = {
      types: {
        party: "autocomplete",
        income: "autocomplete",
        income_campaign: "autocomplete",
        expenses: "autocomplete",
        expenses_campaign: "autocomplete",
        reform_expenses: "autocomplete",
        property_assets: "autocomplete",
        financial_assets: "autocomplete",
        debts: "autocomplete",
        period: "period_mix"
      },
      download: $("#finance_csv_download"),
      states: {
        income: false,
        income_campaign: false,
        expenses: false,
        expenses_campaign: false,
        reform_expenses: false,
        property_assets: false,
        financial_assets: false,
        debts: false
      },
      categories: ["income", "income_campaign", "expenses", "expenses_campaign", "reform_expenses", "property_assets", "financial_assets", "debts" ],
      elem: {
        party: $("#finance_party"),
        income: $("#finance_income"),
        income_campaign:$("#finance_income_campaign"),
        expenses:$("#finance_expenses"),
        expenses_campaign:$("#finance_expenses_campaign"),
        reform_expenses:$("#finance_reform_expenses"),
        property_assets:$("#finance_property_assets"),
        financial_assets:$("#finance_financial_assets"),
        debts:$("#finance_debts"),
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
              else if(t.states[el]) {
                t.data[el] = [gon.main_categories[el]];
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
        at_least_one = false;
        t.categories.forEach(function(d){
          if(t.data.hasOwnProperty(d)) {
            at_least_one = true;
            return;
          }
        });
        if(!at_least_one) { t.animate(); return null; }
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
      id: function(v) {
        var tmp = ["f", v.party];
        this.categories.forEach(function(d){ tmp.push(v[d]); });
        tmp.push(v.period);
        return CryptoJS.MD5(tmp.join(";")).toString();
      },
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
        t.download.attr("href", window.location.pathname + "?filter=finance&" + (params.length ? (params.join("&") + "&") : "") + "format=csv")
      },
      toggle: function(element, turn_on) {
        //console.log(element, turn_on);
        var t = this;
        t.elem[element].parent().attr("data-on", turn_on);
        t.states[element] = turn_on;
      },
      animate: function () {
        [finance_category.find("li div"), explore_button].forEach(function (d) {
          d.one('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', function() { $(this).removeClass("swing animated"); })
          .addClass("swing animated");
        });
      }
    };
  finance_toggle.click(function (event){
    is_type_donation = false;
    var p = finance_toggle.parent().parent();
    donation_toggle.parent().removeClass("active");

    if(!p.hasClass("active")) {
      p.addClass("active");
      filter_type.attr("data-type", "finance");
      filter_extended.attr("data-type", "finance");
      explore.attr("data-type", "finance");
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
      explore.attr("data-type", "donation");
    }
    event.stopPropagation();
  });

  filter_type.find(".back").click(function () {1
    filter_type.toggleClass("in-depth");
  });
  finance_category.find(".finance-category-toggle").click(function(event) {
    //console.log("toggle");
    if(!is_type_donation) { finance_toggle.trigger("click"); }
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
      finance.toggle(sub.attr("data-cat"), true);
    }
    else if(state === "all" || state === "campaign") { // unselect multy select
      sub = t.find(".sub[data-sub='" + state + "']");
      t.attr("data-state", "");
      finance.toggle(sub.attr("data-cat"), false);
    }
    else if(state === "simple") {
      t.attr("data-state", "simpled");
      finance.toggle(cat, true);
    }
    else if(state === "simpled") {
      t.attr("data-state", "simple");
      finance.toggle(cat, false);
    }
    event.preventDefault();
    event.stopPropagation();
  });

// -----------------------------------------------------------------




  function emulate_category_click(cat) {
    var t, tmp, subcat = "all";

    // finance_toggle.trigger("click");
    if(["income_campaign", "expenses_campaign"].indexOf(cat) !== -1) {
      var tmp = cat.split("_");
      cat = tmp[0];
      subcat = tmp[1];
    }

    t = $(".finance-category-toggle[data-cat='" + cat + "']"), tp = t.attr("data-state");

    if(tp === "simple" || tp === "simpled") {
      t.trigger("click");
    }
    else {
      t.attr("data-state", subcat);
      finance.toggle(cat, true);
    }
  }
  function create_list_item(list, text, vbool) {
    list.html(vbool ? "<span>" + text + "<i class='close' title='" + gon.filter_item_close + "'></i></span>" : "").toggleClass("hidden", !vbool);
  }
  function li(id, text) {
    return "<li data-id='"+id+"'>"+text+"<i class='close' title='" + gon.filter_item_close + "'></i></li>";
  }
  function bind() {
    window.onpopstate = function(event) {
       //console.log("onpopstate location: " + window.location + ", state: " + JSON.stringify(event.state));
    };
    filter_extended.find(".filter-toggle").click(function(){
      filter_extended.toggleClass("active");
      overlay.removeClass("hidden");
      event.stopPropagation();
    });
    filter_extended.find(".filter-header .close").click(function(){
      overlay.addClass("hidden");
      filter_extended.toggleClass("active");
    });
    filter_extended.find(".filter-input .toggle").click(function(){
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
    filter_extended.find(".filter-input button.clear").click(function () {
      autocomplete.clear($(this).parent().attr("data-autocomplete-id"));
    });
    $(window).on("resize", function(){
      filter_extended.find(".filter-inputs").css("max-height", $(window).height() - filter_extended.find(".filter-toggle").offset().top);
    });


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
      else if(type === "range") {

        p.find(".input-group input[type='number']").val(null);
      }
      else if(type === "radio") {
        p.find(".input-group input[type='radio']:checked").prop("checked", false);
      }
      else if(type === "checkbox") {
        p.find(".input-group input[type='checkbox']:checked").prop("checked", false);
      }
      else if(type === "period_mix") {
        p.find(".input-group .input-checkbox-group input[type='checkbox'][value='" + li_span.attr("data-id") + "']:checked").prop("checked", false);
      }

      if(type !== "autocomplete") {
        li_span.remove();
      }
      event.stopPropagation();
    });
    $("#reset").click(function(){
      if(is_type_donation) {
        donation.reset();
      }
      else {
        finance.reset();
      }
    });
    explore_button.click(function(){ filter(); });

    function export_object(source, source_type, action) {
      console.log(source,source_type,action);

      var tmp,
      mimes = {
        "png": "image/png",
        "jpeg": "image/jpeg",
        "svg": "image/svg+xml",
        "pdf": "application/pdf",
      };

      if(source_type === "chart") {
        tmp = $(source).highcharts();
        if(action === "print") {
          chart.print();
        }
        else {
          tmp.exportChart({ type: mimes[action] });
        }
      }
      else if(source_type === "table") {
        // if(action == "csv") {
        //   $(source).find(".dt-buttons [data-action='" + action + "'] a[]").trigger("click");
        // }
      }


    }
    $(".download_list a").click(function(){
      var t = $(this), action = t.attr("data-type"), li = t.parent(),
        ul = li.parent(), source_type = ul.attr("data-type"),
        source = "#" + ul.attr("data-object") + "_" + source_type;

      export_object(source, source_type, action);
    });

    $(".chart_download a").click(function(){
      var t = $(this), type = t.attr("data-type"), p = t.parent().parent(), target = p.attr("data-target"),
      chart = $(target).highcharts(),
      mimes = {
        "png": "image/png",
        "jpeg": "image/jpeg",
        "svg": "image/svg+xml",
        "pdf": "application/pdf",
      };
      //<a href="/en/explore?expenses%5B%5D=5784e800fbb6bd2f46a9e344&amp;filter=finance&amp;income%5B%5D=5784e800fbb6bd2f46a9e328&amp;income%5B%5D=5784e800fbb6bd2f46a9e319&amp;party%5B%5D=5784e800fbb6bd2f46a9e1d5&amp;party%5B%5D=5784e800fbb6bd2f46a9e1f8&amp;period%5B%5D=5784e800fbb6bd2f46a9e20b&amp;period%5B%5D=5784e800fbb6bd2f46a9e20a&amp;period%5B%5D=5784e800fbb6bd2f46a9e209&amp;format=csv" id="donation_csv_download" class="download" title="Download table"><i></i></a>
      //console.log(target, type, mimes[type]);
      if(type === "print") {
        chart.print();
      }
      else {
        chart.exportChart({ type: mimes[type] });
      }
    });
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
    $(".pane[data-type='finance'] .actions .left > div[data-view-toggle]").on("click", function() {
      $(".pane[data-type='finance']").attr("data-view-current", $(this).attr("data-view-toggle"));
      $(".pane[data-type='finance'] .actions .download_list").attr("data-type", $(this).attr("data-view-toggle"));
    });
  }

  function filter() {
    //console.log("start filter", is_type_donation);
    var filters = {},
      remote_required = false, tmp, cacher_id, donation_id, finance_id;

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



      if(remote_required) {
        $.ajax({
          url: "explore_filter",
          dataType: 'json',
          data: filters,
          success: function(data) {
            if(data.hasOwnProperty("donation")) { filter_callback(js.cache[donation_id] = data.donation, "donation"); }
            if(data.hasOwnProperty("finance")) { filter_callback(js.cache[finance_id] = data.finance, "finance"); }
          }
        });
      }
    }
  }


  function render_table(type, table) {
    // console.log("table data", table);
    if(type === "donation") {
      donation_total_amount.text(table.total_amount);
      donation_total_donations.text(table.total_donations);

      donation_table.DataTable({
        destroy: true,
        "aaData": table.data,
        "aoColumns": table.header.map(function(m,i) {
          return { "title": m, "sClass": table.classes[i], "visible": i != 0 };
        }),
        "info": false,
        dom: "fltrp"
      });
    }
    else if(type === "finance") {
      var table_html = "<thead>", colspan = 0, tmp, klass;
      table.header.forEach(function(row, row_i) {

        table_html += "<tr>";
        row.forEach(function(col, col_i) {
          if(col === null) {
            ++colspan;
          }
          else {
            tmp = "";
            klass = table.header_classes[row_i][col_i];
            klass = klass !== null ? " class='" + klass + "'" : "";

            if(colspan) {
              tmp = " colspan='" + (colspan+1) + "'";
              colspan = 0;
            }
            table_html += "<th" + klass + tmp +">" + col + "</th>";
          }
        });
        table_html += "</tr>";
      });
      table_html += "</thead><tbody>";


      table.data.forEach(function(row, row_i) {
        table_html += "<tr>";
        row.forEach(function(col, col_i) {
          klass = table.classes[col_i];
          klass = klass !== null ? " class='" + klass + "'" : "";
          table_html += "<td" + klass + ">" + col + "</th>";
        });
        table_html += "</td>";
      });
      table_html += "</tbody>";

      if(typeof finance_datatable !== "undefined") {
        finance_datatable.destroy();
      }
      finance_table.html(table_html);
      finance_datatable = finance_table.DataTable({
        destroy: true,
        //"aaData": table.data,
        // "aoColumns": table.header.map(function(m,i) {
        //   return { "title": m, "sClass": table.classes[i], "visible": i != 0 };
        // }),
        "info": false,
        dom: "Bfltrp"
        // ,
        // buttons: [
        //   {
        //     extend:    'print',
        //     text:      '<div data-action="print"></div>',
        //     title: 'Print'
        //   },
        //   {
        //     extend:    'csv',
        //     text:      '<div data-action="csv"></div>',
        //     title: 'Csv'
        //   }
        // ]
      });
    }

  }
  function filter_callback(data, partial) {
     console.log("filter_callback", data);
     // data =  undefined; // test for not found data
    var is_data_ok = typeof data !== "undefined";
    content.find(".panes").toggleClass("not-found", !is_data_ok);
    if(is_data_ok) {
      if(partial === "donation") {
        bar_chart("#donation_chart_1", data.chart1, data.chart1_title, data.chart_subtitle, "#EBE187");
        bar_chart("#donation_chart_2", data.chart2, data.chart2_title, data.chart_subtitle, "#B8E8AD");
      }
      else {
        //grouped_column_chart("#finance_chart", data.chart1, "#fff");
        grouped_advanced_column_chart("#finance_chart", data.chart1, "#fff");
      }
      render_table(partial, data.table);
    }
  }
  (function init() {
    Highcharts.setOptions({
      lang: {
        numericSymbols: [ "k" , "M" , "G" , "T" , "P" , "E"]
      },
      colors: [ "#D36135", "#DDCD37", "#5B85AA", "#F78E69", "#A69888", "#88D877", "#5D675B", "#A07F9F", "#549941", "#35617C", "#694966", "#B9C4B7"],
      credits: {
        enabled: true,
        href: gon.url,
        // position: undefined
        // style: undefined
        text: gon.app_name
      }
    });
    (function(H) { // for highchart to recognize maxPointWidth property
        var each = H.each;
        H.wrap(H.seriesTypes.column.prototype, 'drawPoints', function(proceed) {
            var series = this;
            if(series.data.length > 0 ){
                var width = series.barW > series.options.maxPointWidth ? series.options.maxPointWidth : series.barW;
                each(this.data, function(point) {
                    point.shapeArgs.x += (point.shapeArgs.width - width) / 2;
                    point.shapeArgs.width = width;
                });
            }
            proceed.call(this);
        })
    })(Highcharts)

    bind();
    is_type_donation = gon.gonned_type === "donation";

    filter();
  })();

  function bar_chart(elem, series_data, title, subtitle, bg) {
    //console.log("chart", elem, series_data);
    $(elem).highcharts({
      chart: {
          type: 'bar',
          backgroundColor: bg,
          height: 60*(Math.round(title.length/40)+1) + 40 * series_data.length
      },
      exporting: {
        buttons: {
          contextButton: {
            enabled: false
          }
        }
      },
      title: {
        text: title,
        style: {
          color: "#5d675b",
          fontSize:"18px",
          fontFamily: "firasans_r",
          textShadow: 'none'
        }
      },
      subtitle: {
        text: subtitle,
        style: {
          color: "#5d675b",
          fontSize:"12px",
          fontFamily: "firasans_book",
          textShadow: 'none'
        }
      },
      xAxis: {
        type: "category",
        lineWidth: 0,
        tickWidth: 0,
        labels: {
          style: {
            color: "#5d675b",
            fontSize:"14px",
            fontFamily: "firasans_book",
            textShadow: 'none'
          }
        }
      },
      yAxis: { visible: false },
      legend: { enabled: false },
      plotOptions: {
          bar: {
              color:"#ffffff",
              dataLabels: {
                  enabled: true,
                  padding: 6,
                  style: {
                    color: "#5d675b",
                    fontSize:"14px",
                    fontFamily: "firasans_r",
                    textShadow: 'none'
                  }
              },
              pointInterval:1,
              pointWidth:17,
              pointPadding: 0,
              groupPadding: 0,
              borderWidth: 0,
              shadow: false
          }
      },
      series: [{ data: series_data }],
      tooltip: {
        backgroundColor: "#DCE0DC",
        followPointer: true,
        shadow: false,
        borderWidth:0,
        style: {
          color: "#5D675B",
          fontSize:"14px",
          fontFamily: "firasans_r",
          textShadow: 'none',
          fontWeight:'normal'
        },
        formatter: function() {
          return "<b>" + this.key + "</b>: " + Highcharts.numberFormat(this.y);
        }
      }
    });
  }
  function grouped_column_chart(elem, resource, bg) {
    console.log("chart", elem, resource);
    $(elem).highcharts({
      chart: {
          type: 'column',
          backgroundColor: bg,
          height: 400,
          width:800
      },
      exporting: {
        buttons: {
          contextButton: {
            enabled: false
          }
        }
      },
      title: {
        text: resource.title,
        margin: 40,
        style: {
            fontFamily:"firasans_r",
            fontSize:"18px",
            color: "#5d675b"
        },
        useHTML: true
      },
      xAxis: {
        type: "category",
        categories: resource.categories,
        // gridLineColor: "#5D675B",
        // gridLineWidth:1,
        // gridLineDashStyle: "Dash",
        lineWidth: 1,
        lineColor: "#5D675B",
        tickWidth: 0,
        // tickColor: "#5D675B",
        // tickLength: 50,
        // tickPosition: "outside",
        min: 0,
        labels: {
          style: {
            color: "#5d675b",
            fontSize:"14px",
            fontFamily: "firasans_book",
            textShadow: 'none'
          }
        }
      },
      yAxis: [
      {
        title: { enabled: false },
        gridLineColor: "#eef0ee",
        gridLineWidth:1,
        style: {
          color: "#5d675b",
          fontSize:"14px",
          fontFamily: "firasans_book",
          textShadow: 'none'
        }
      },
      {
        linkedTo:0,
        title: { enabled: false },
        opposite: true,
        style: {
          color: "#7F897D",
          fontSize:"12px",
          fontFamily: "firasans_r",
          textShadow: 'none'
        }
      }
      ],
      legend: {
          enabled: true,
          symbolWidth:10,
          symbolHeight:10,
          shadow: false,
          itemStyle: {
            color: "#5d675b",
            fontSize:"14px",
            fontFamily: "firasans_book",
            textShadow: 'none',
            fontWeight:'normal'
          }
       },

      plotOptions: {
        column:{
          maxPointWidth: 20
        }
      },
      series: resource.series,
      tooltip: {
        backgroundColor: "#DCE0DC",
        followPointer: true,
        shadow: false,
        borderWidth:0,
        style: {
          color: "#5D675B",
          fontSize:"14px",
          fontFamily: "firasans_r",
          textShadow: 'none',
          fontWeight:'normal'
        }
      }
    });
  }
  function grouped_advanced_column_chart(elem, resource, bg) {
    console.log(resource);
    $(elem).highcharts({
      chart: {
          type: 'column',
          backgroundColor: bg,
          height: 400,
          width:800
      },
      exporting: {
        buttons: {
          contextButton: {
            enabled: false
          }
        }
      },
      title: {
        text: resource.title,
        margin: 40,
        style: {
            fontFamily:"firasans_r",
            fontSize:"18px",
            color: "#5d675b"
        },
        useHTML: true
      },
      xAxis: {
        type: "category",
        categories: resource.categories,
        gridLineColor: "#5D675B",
        gridLineWidth:1,
        gridLineDashStyle: "Dash",
        lineWidth: 1,
        lineColor: "#5D675B",
        tickWidth: 1,
        tickColor: "#5D675B",

        labels: {
          style: {
            color: "#5d675b",
            fontSize:"14px",
            fontFamily: "firasans_book",
            textShadow: 'none'
          },
          //useHTML: true,
          step:1
        }
      },
      yAxis: [
      {
        title: { enabled: false },
        gridLineColor: "#eef0ee",
        gridLineWidth:1,
        style: {
          color: "#5d675b",
          fontSize:"14px",
          fontFamily: "firasans_book",
          textShadow: 'none'
        }
      },
      {
        linkedTo:0,
        title: { enabled: false },
        opposite: true,
        style: {
          color: "#7F897D",
          fontSize:"12px",
          fontFamily: "firasans_r",
          textShadow: 'none'
        }
      }
      ],
      legend: {
          enabled: true,
          symbolWidth:10,
          symbolHeight:10,
          shadow: false,
          itemStyle: {
            color: "#5d675b",
            fontSize:"14px",
            fontFamily: "firasans_book",
            textShadow: 'none',
            fontWeight:'normal'
          }
       },

      plotOptions: {
        column:{
          maxPointWidth: 20
        }
      },
      series: resource.series,
      tooltip: {
        backgroundColor: "#DCE0DC",
        followPointer: true,
        shadow: false,
        borderWidth:0,
        style: {
          color: "#5D675B",
          fontSize:"14px",
          fontFamily: "firasans_r",
          textShadow: 'none',
          fontWeight:'normal'
        }
      }
    });
  }


  // dev block
  // filter_extended.find(".filter-toggle").trigger("click");
  // filter_extended.find(".filter-input:nth-of-type(3) .toggle").trigger("click");

});

