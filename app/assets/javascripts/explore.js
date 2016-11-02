/* global $ */
/*eslint no-console: "error"*/
//= require jquery-ui/datepicker
//= require dataTables.pagination.js
//= require jquery-ui/tooltip
//= require moment
//= require explore_global
//= require js_dialog

$(document).ready(function (){
  // console.log("explore ready");
  var
    w = 0,
    h = 0,
    explore = $("#explore"),
    explore_button = $("#explore_button"),
    finance_toggle = $("#finance_toggle"),
    donation_toggle = $("#donation_toggle"),
    filter_type = $("#filter_type"),
    filter_extended = $("#filter_extended"),
    finance_category = $("#finance_category"),
    view_content = $(".view-content"),
    view_not_found = $(".not-found"),
    loader = $(".view-loader"),
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

            if(p.is("[data-url]")) {
              ul.addClass("loading");
              $.ajax({
                url: p.attr("data-url"),
                dataType: "json",
                data: { q: v },
                success: function(data) {
                  var html = "";
                  // console.log("back", data);
                  data.forEach(function(d) {
                    html += "<li><div class='item" + (autocomplete.has(autocomplete_id, d[0]) ? " selected" : "") + "' data-id='" + d[0] + "' data-extra='" + d[2] + "'>" + d[1] + "</li>";
                  });
                  ul.html(html);//.addClass("active");
                },
                complete: function () {
                  ul.removeClass("loading");
                }
              });
            }
            else if(p.is("[data-local]")) {
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
            // console.log(autocomplete_id, t.attr("data-id"), t.text());
            var extra = t.attr("data-extra");
            extra = typeof extra  !== "undefined" ? " (" + extra + ")": "";
            autocomplete.push(autocomplete_id, t.attr("data-id"), t.text() + extra);
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
      name: "donation",
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
      sid: undefined,
      get: function() {
        var t = this, tp, tmp, tmp_v, tmp_d, tmp_o, lnk;
        t.data = { filter: "donation" };;
        Object.keys(this.elem).forEach(function(el){
          var is_elem = ["period", "amount", "monetary", "nature"].indexOf(el) === -1;

          (is_elem ? [t.elem[el]] : Object.keys(t.elem[el]).map(function(m){ return t.elem[el][m]; })).forEach(function(elem, elem_i){
            tmp = $(elem);
            tp = tmp.attr("data-type");
            if(tp === "autocomplete") {
              lnk = tmp.attr("data-autocomplete-view");
              if(autocomplete.hasOwnProperty(lnk)) {
                tmp_v = Object.keys(autocomplete[lnk]);
                if(tmp_v.length) {
                  t.data[el] = tmp_v;
                }
                else {
                  delete t.data[el];
                }
              }
            }
            else if(tp === "period") {
              tmp_v = tmp.datepicker('getDate');
              tmp_d = t.data.hasOwnProperty(el) ? t.data[el] : [-1, -1];
              if(isDate(tmp_v)) {
                tmp_d[elem_i] =  Date.UTC(tmp_v.getFullYear(), tmp_v.getMonth(), tmp_v.getDate(), 0, 0, 0);
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
        return t.data;
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
              v = [moment.utc(v[0]).format(gon.mdate_format), moment.utc(v[1]).format(gon.mdate_format)];
              el.from.datepicker('setDate', v[0]);
              el.to.datepicker('setDate', v[1]);
              tmp = formatRange(v);
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
              tmp = el.prop("checked", v);
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
      id: function() {
        var t = this, tmp = [], p, except = ["period", "amount"];
        Object.keys(t.data).sort().forEach(function (k) {
          p = t.data[k];
          p = Array.isArray(p) && except.indexOf(k) === -1 ? p.sort() : [p];
          tmp.push(k + "=" + p.join(","));
        });
        return CryptoJS.MD5(tmp.join("&")).toString();
      },
      url: function (sid) {
        if(typeof sid === "undefined") { sid = this.sid; }
        js.sid = sid;
        this.sid = sid;
        window.history.pushState(sid, null, gon.path + "/" + sid);
        this.download.attr("href", gon.path + "/" + sid + "?format=csv");
      }
    },
    finance = {
      name: "finance",
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
      sid: undefined,
      get: function() {
        var t = this, tp, tmp, tmp_v, tmp_d, lnk;
        t.data = { filter: "finance" };
        // console.log(autocomplete, "before", t.data);
        Object.keys(this.elem).forEach(function(el){
          var is_elem = [].indexOf(el) === -1;
          (is_elem ? [t.elem[el]] : Object.keys(t.elem[el]).map(function(m){ return t.elem[el][m]; })).forEach(function(elem, elem_i){
            tmp = $(elem);
            tmp_v = [];
            tp = tmp.attr("data-type");
            if(tp === "autocomplete") {
              lnk = tmp.attr("data-autocomplete-view");
              if(autocomplete.hasOwnProperty(lnk)) {
                tmp_v = Object.keys(autocomplete[lnk]);
              }
              else if(t.states[el]) {
                tmp_v = [gon.main_categories[el]];
              }

              if(tmp_v.length) {
                t.data[el] = tmp_v;
              }
              else {
                delete t.data[el];
              }
            }
            else if(tp === "period_mix") {
              tmp_d = tmp.find("li[data-id]");
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
        return t.data;
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
      id: function() {
        var t = this, tmp = [], p;
        Object.keys(t.data).sort().forEach(function (k) {
          p = t.data[k];
          p = Array.isArray(p) ? p.sort() : [p];
          tmp.push(k + "=" + p.join(","));
        });
        return CryptoJS.MD5(tmp.join("&")).toString();
      },
      url: function (sid) {
        if(typeof sid === "undefined") { sid = this.sid; }
        js.sid = sid;
        this.sid = sid;
        window.history.pushState(sid, null, gon.path + "/" + sid);
        this.download.attr("href", gon.path + "/" + sid + "?format=csv");
      },
      toggle: function(element, turn_on) {
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
    js.is_donation = false;
    finance.url();
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
    js.is_donation = true;
    donation.url();
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
    // console.log("toggle", js.is_donation);
    if(js.is_donation) { finance_toggle.trigger("click"); }
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
  function resize() {
    w = $(window).width();
    h = $(window).height();
  }
  function bind() {
    window.onpopstate = function(event) {
       //console.log("onpopstate location: " + window.location + ", state: " + JSON.stringify(event.state));
    };
    filter_extended.find(".filter-toggle").click(function(){
      filter_extended.toggleClass("active");
      loader.removeClass("hidden");
      event.stopPropagation();
    });
    filter_extended.find(".filter-header .close").click(function(){
      loader.addClass("hidden");
      filter_extended.toggleClass("active");
    });
    filter_extended.find(".filter-input .toggle, input").click(function(){
      var t = $(this).closest(".filter-input"),
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
      if($(this).hasClass("toggle")) {
        t.toggleClass("expanded", !state);
      }
    });
    filter_extended.find(".filter-input button.clear").click(function () {
      autocomplete.clear($(this).parent().attr("data-autocomplete-id"));
    });
    $(window).on("resize", function(){
      resize();
      filter_extended.find(".filter-inputs").css("max-height", $(window).height() - filter_extended.find(".filter-toggle").offset().top);
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
      clear_embed();
      if(js.is_donation) {
        donation.reset();
      }
      else {
        finance.reset();
      }
    });
    explore_button.click(function(){ clear_embed(); filter(); });
    function clear_embed() {
      js.esid[js.is_donation ? "d" : "f"] = undefined;
    }
    $(".chart_download a").click(function(){
      var t = $(this), type = t.attr("data-type"), p = t.parent().parent(), target = p.attr("data-target"),
      chart = $(target).highcharts(),
      mimes = {
        "png": "image/png",
        "jpeg": "image/jpeg",
        "svg": "image/svg+xml",
        "pdf": "application/pdf",
      };
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
      var t = $(this), tp = t.attr("data-view-toggle"), p = t.closest(".actions"), r = p.find(".right .share, .right .embed");
      p.attr("data-type", tp);
      $(".pane[data-type='finance']").attr("data-view-type", tp);
      //$(".pane[data-type='finance'] .actions .download_list").attr("data-type", tp);
      // p.find(".embed").attr("data-embed", tp === "chart" ? "f-ca" : "f-t");

    });

    $(document).tooltip({
      content: function() { return $(this).attr("data-retitle"); },
      items: "text[data-retitle]",
      track: true
    });

    $(document).on("click", "[data-dialog]", function () {
      var t = $(this), pars = t.attr("data-dialog").split(";"),
        options = { chart: (pars.length === 2 ? pars[1] : "") };
      if(pars[0] === "share") {
        options["title"] = js.share["#" + t.attr("data-share-title")];
      }
      js_dialog.open(pars[0], options);
    });
  }

  function filter() {
    loader.fadeIn();
    //console.log("start filter", js.is_donation);
    var tmp, cacher_id, _id, _id, finance_id, obj;

    if(gon.gonned) {
      [donation, finance].forEach( function (obj) {
        obj.set_by_url();
        tmp = obj.get();
        _id = obj.id();
        js.cache[_id] = gon[obj.name + "_data"];
        // console.log("gonnned",js.cache[_id].sid);
        obj.url(js.cache[_id].sid);
        filter_callback(js.cache[_id], obj.name);
      });
      gon.gonned = false;
    } else {
      obj = js.is_donation ? donation : finance;
      tmp = obj.get();
      _id = obj.id();


      if(!js.cache.hasOwnProperty(_id)) {
        var filters = {};
        delete tmp["filter"];
        filters[obj.name] = tmp;
        // console.log("-------------------", _id, filters);
        $.ajax({
          url: gon.filter_path,
          dataType: 'json',
          data: filters,
          success: function(data) {
            // console.log("explore_filter", data);
            js.cache[_id] = data[obj.name];
            obj.url(js.cache[_id].sid);
            if(data.hasOwnProperty("donation")) { filter_callback(data.donation, "donation"); }
            if(data.hasOwnProperty("finance")) { filter_callback(data.finance, "finance"); }
          }
        });
      }
      else {
        obj.url(js.cache[_id].sid);
        filter_callback(js.cache[_id], obj.name);
      }
    }
  }
  function filter_callback(data, partial) {
    //console.log("filter_callback", data, partial);
    view_not_found.addClass("hidden");
    var is_data_ok = typeof data !== "undefined";
    if(is_data_ok) {
      if(partial === "donation") {
        bar_chart("#donation_chart_1", data.ca, "#EBE187");
        bar_chart("#donation_chart_2", data.cb, "#B8E8AD");
      }
      else {
        //grouped_column_chart("#finance_chart", data.ca, "#fff");
        grouped_advanced_column_chart("#finance_chart", data.ca, "#fff");
      }
      render_table(partial, data.table);
    }
    else {
      view_not_found.removeClass("hidden");
    }
    loader.fadeOut();
  }

  function render_table(type, table) {
    // console.log("table data", table);
    if(type === "donation") {
      // console.log(table);
      donation_total_amount.text(table.total_amount);
      donation_total_donations.text(table.total_donations);
      var prev = undefined, alt_color = true,
        dt = donation_table.DataTable({
          responsive: true,
          destroy: true,
          order: [],
          "aaData": table.data,
          "aoColumns": table.header.map(function(m,i) {
            return { "title": m, "sClass": table.classes[i], "visible": i != 0 };
          }),
          "info": false,
          dom: "fltrp",
          createdRow: function ( row, data, index ) {
            if(data[2] !== prev) {
              alt_color = !alt_color;
            }
            if(alt_color) {
              $(row).addClass('alt');
            }
            prev = data[2];
          }
        });
      dt.on("draw", function (e, settings) {
        if(settings.aaSorting.length) {
          $(this).toggleClass("highlighted", settings.aaSorting[0][0] === 1);
        }
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
        responsive: true,
        //"aaData": table.data,
        // "aoColumns": table.header.map(function(m,i) {
        //   return { "title": m, "sClass": table.classes[i], "visible": i != 0 };
        // }),
        "info": false,
        dom: "Bfltrp"
      });
    }
  }
  function bar_chart(elem, resource, bg) {
    // console.log("chart", elem, resource);
    js.share[elem] = encodeURI(resource.title + "( " + resource.subtitle + " )" + " | " + gon.app_name_long);
    $(elem).highcharts({
      chart: {
          type: 'bar',
          backgroundColor: bg,
          height: 60*(Math.round(resource.title.length/40)+1) + 40 * resource.series.length,
          width: w > 992 ? (view_content.width()-386)/2 : w - 12,
          events: {
            load: function () {
              var tls = $(this.container).find(".highcharts-xaxis-labels text title"),
                p = tls.parent();
              p.attr("data-retitle", tls.text());
              tls.remove();
            }
          }
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
        style: {
          color: "#5d675b",
          fontSize:"18px",
          fontFamily: "firasans_r",
          textShadow: 'none'
        }
      },
      subtitle: {
        text: resource.subtitle,
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
          // ,
          // formatter: function(a,b,c) {
          //   return this.value + "<title>hello</title>";
          // }
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
      series: [{ data: resource.series }],
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
    // console.log("chart", elem, resource);
    $(elem).highcharts({
      chart: {
          type: 'column',
          backgroundColor: bg,
          height: 400,
          width: w > 992 ? (view_content.width()-28)/2 : w - 12,
          spacingLeft: 20
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
        lineWidth: 1,
        lineColor: "#5D675B",
        tickWidth: 0,
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
          maxPointWidth: 60
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
    // console.log("fca", resource);
    js.share[elem] = encodeURI(resource.title + " | " + gon.app_name_long);
    $(elem).highcharts({
      chart: {
          type: 'column',
          backgroundColor: bg,
          height: 400,
          width: w > 992 ? (view_content.width()-28)/2 : w - 12
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
          maxPointWidth: 40
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
  function init_highchart () {
    Highcharts.setOptions({
      lang: {
        numericSymbols: gon.numericSymbols
      },
      colors: [ "#D36135", "#DDCD37", "#5B85AA", "#F78E69", "#A69888", "#88D877", "#5D675B", "#A07F9F", "#549941", "#35617C", "#694966", "#B9C4B7"],
      credits: {
        enabled: true,
        href: gon.root_url,
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
    })(Highcharts);
  }

  // dev block
  // filter_extended.find(".filter-toggle").trigger("click");
  // filter_extended.find(".filter-input:nth-of-type(3) .toggle").trigger("click");
  (function init() {
    init_highchart();
    bind();
    js.is_donation = gon.is_donation;
    filter();
  })();
});
