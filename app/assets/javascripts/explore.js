/* global $ */
/*eslint no-console: "error"*/
//= require jquery-ui/datepicker
var dn;
$(document).ready(function (){
  // console.log("here");
  var js = {
      cache: {}
    },
    finance_toggle = $("#finance_toggle"),
    donation_toggle = $("#donation_toggle"),
    filter_type = $("#filter_type"),
    is_type_donation = true,
    filter_extended = $("#filter_extended"),
    finance_category = $("#finance_category"),
    content = $("#content"),
    overlay = $(".overlay"),
    autocomplete = {
      push: function(autocomplete_id, key, value) {
        if(!this.hasOwnProperty(autocomplete_id)) {
          this[autocomplete_id] = {};
        }
        if(!this[autocomplete_id].hasOwnProperty(key)) {
          $("[data-autocomplete-view='" + autocomplete_id + "']").append("<li data-id='"+key+"'>"+value+"<i class='close' title='" + gon.filter_item_close + "'></i></li>");
          this[autocomplete_id][key] = value;
        }
      },
      pop: function(autocomplete_id, key) {
        if(this.hasOwnProperty(autocomplete_id) && this[autocomplete_id].hasOwnProperty(key)) {
          $("[data-autocomplete-view='" + autocomplete_id + "'] li[data-id='" + key + "']").remove();
          delete this[autocomplete_id][key];
        }
      },
      clear: function(autocomplete_id) {
        if(this.hasOwnProperty(autocomplete_id)) {
          $("[data-autocomplete-view='" + autocomplete_id + "'] li").remove();
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
            if(p.is("[data-local]")) {
              ul.find("li").hide();
              var regex = new RegExp(".*" + v + ".*", "i");
              gon[p.attr("data-local")].forEach(function(d) {
                if(d[1].match(regex) !== null) {
                  ul.find("li[data-id='" + d[0] + "']").show();
                }

              });
              console.log("local");
            }
            else {
              console.log("ajax");
              $.ajax({
                url: p.attr("data-url"),
                dataType: 'json',
                data: { q: v },
                success: function(data) {
                  var html = "";
                  data.forEach(function(d) {
                    html += "<li data-id='" + d[1] + "'" + (autocomplete.has(autocomplete_id, d[1]) ? "class='selected'" : "") + " tabindex='1'>" + d[0] + "</li>";
                  });
                  p.find("ul").html(html).addClass("active");
                  console.log("ajax success");
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
      bind: function() {
        $(".autocomplete input").on("change paste keyup", this.onchange);
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
           //console.log("click keypress autocomplete name");
          if(event.type === "keypress" && event.keyCode !== 13) { return; }
          var t = $(this), dropdown = t.parent(), p = dropdown.parent(), is_selected = t.hasClass("selected");

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


        $(document).on("click", ".list li .close", function(event) {
          var t = $(this).parent(), list = t.parent(), autocomplete_id = list.attr("data-autocomplete-view");
          $("[data-autocomplete-id='" + autocomplete_id + "'] .dropdown li[data-id='" + t.attr("data-id") + "']").toggleClass("selected");
          autocomplete.pop(autocomplete_id, t.attr("data-id"));
          event.stopPropagation();
        });
      }
    },
    donation = {
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
        type: {
          monetary: $("#donation_type_monetary"),
          nonmonetary: $("#donation_type_nonmonetary")
        },
        multiple: $("#donation_multiple_yes")

        // reset: $("#donation_reset"),
        // explore: $("#donation_explore")
      },
      data: {},
      get: function() {
        var t = this, tp, tmp, tmp_v, tmp_d, tmp_o, lnk;
        t.data = {};
        Object.keys(this.elem).forEach(function(el){
          var is_elem = Object.keys(t.elem[el]).length;

          (is_elem ? Object.keys(t.elem[el]).map(function(m){ return t.elem[el][m]; }) : [t.elem[el]]).forEach(function(elem, elem_i){
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
      reset: function() {
        $(".filter-inputs[data-type='donation'] .filter-input").each(function(i,d) {
          var t = $(this);
            field = t.attr("data-field"),
            type = t.attr("data-type");
             list = t.find(".list");

            if(type === "autocomplete") {
              autocomplete.clear(t.find(".autocomplete[data-autocomplete-id]").attr("data-autocomplete-id"));
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
      validate: function() {},
      id: function(data) {
        var period = [-1, -1], amount = [-1, -1];
        if(data.hasOwnProperty("period")) {
          period = data.period;
        }
        if(data.hasOwnProperty("amount")) {
          amount = data.amount;
        }
        return CryptoJS.MD5(["d", data.donors, period.join(";"), amount.join(";"), data.parties, data.monetary,data.multiple].join(";")).toString();
      }
    };
    dn = donation;
     // console.log(donation.get(), donation);
  // gon.donation_period_min = new Date(gon.donation_period_min);
  // gon.donation_period_max = new Date(gon.donation_period_max);
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






  function bind() {
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
            tmp.push(tmp2 ? tmp2.format("mm/dd/yyyy") : null);
          });
          tmp = formatRange(tmp);
          list.html(tmp ? "<span>" + tmp + "<i class='close' title='" + gon.filter_item_close + "'></i></span>" : "").toggleClass("hidden", !tmp);
        }
        else if(type === "range") {
          tmp = [];
          t.find(".input-group input[type='number']").each(function(i, d){
            tmp2 = $(d).val();
            tmp.push(tmp2 !== "" ? tmp2 : null);

          });
          tmp = formatRange(tmp);
          list.html(tmp ? "<span>" + tmp + "<i class='close' title='" + gon.filter_item_close + "'></i></span>" : "").toggleClass("hidden", !tmp);
        }
        else if(type === "radio") {
          tmp = t.find(".input-group input[type='radio']:checked");
          list.html(tmp.length ? "<span>" + tmp.next().text() + "<i class='close' title='" + gon.filter_item_close + "'></i></span>" : "").toggleClass("hidden", !tmp.length);
        }
        else if(type === "checkbox") {
          tmp = t.find(".input-group input[type='checkbox']:checked");
          list.html(tmp.length ? "<span>" + tmp.next().text() + "<i class='close' title='" + gon.filter_item_close + "'></i></span>" : "").toggleClass("hidden", !tmp.length);
        }
      }
      t.toggleClass("expanded", !state);
    });
    $(window).on("resize", function(){
      filter_extended.find(".filter-inputs").css("max-height", $(window).height() - filter_extended.find(".filter-toggle").offset().top);
    });


    donation.elem.period.from.datepicker({
      firstDay: 1,
      changeMonth: true,
      changeYear: true,
      onClose: function( selectedDate ) {
        donation.elem.period.to.datepicker( "option", "minDate", selectedDate );
      }
    });
    donation.elem.period.to.datepicker({
      firstDay: 1,
      changeMonth: true,
      changeYear: true,
      onClose: function( selectedDate ) {
        donation.elem.period.from.datepicker( "option", "maxDate", selectedDate );
      }
    });

    $("#donation_period_campaigns a").click(function(){
      var t = $(this), v = t.attr("data-value").split(";");
      console.log(v);
      donation.elem.period.from.datepicker('setDate', new Date(v[0]));
      donation.elem.period.to.datepicker('setDate', new Date(v[1]));
       console.log("radio");
    });
    $(document).on("click", ".list > span .close", function(event) {
      var t = $(this);
        p = t.closest(".filter-input"),
        field = p.attr("data-field"),
        type = p.attr("data-type");
        t.parent().remove();

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
    $("#explore_button").click(function(){ filter(); });
    autocomplete.bind();
  }

  var first_filter = true;
  function filter() {
    console.log("start filter");
    var filters = {},
      remote_required = false;

    if(is_type_donation) {
      // test if not cached remote_required
      filters["donation"] = donation.get();
       console.log(donation.id(filters["donation"]));
      remote_required = true;
      console.log("donation", filters["donation"]);
      // content.text("donation");

    }
    else {
      // test if not cached
      // remote_required
      //
      filters["finance"] = donation.get();
      // content.text("finance");
    }

    if(remote_required) {
      $.ajax({
        url: "explore_filter",
        dataType: 'json',
        data: filters,
        success: function(data) {
          console.log("remote filtered data", data);
          if(data.hasOwnProperty("donation")) {

          }
          if(data.hasOwnProperty("finance")) {

          }
          filter_callback(data);

          //console.log(data, "filter donation", donation.get());
          // var html = "";
          // data.forEach(function(d) {
          //   html += "<li data-id='" + d[1] + "'" + (autocomplete.has(autocomplete_id, d[1]) ? "class='selected'" : "") + " tabindex='1'>" + d[0] + "</li>";
          // });
          // p.find("ul").html(html).addClass("active");
          // console.log("ajax success");
        }
      });
    }

  }
  function filter_callback(data) {
     console.log("filter_callback`",data);
    //bar_chart(data.donation);
  }

  bind();
  filter();
  function bar_chart(data) {
     console.log("building highcharts", data.map(function(m) { return m.value;}));
      $('#donation_chart_1').highcharts({
        chart: {
            type: 'bar',
            backgroundColor: "transparent",
            height: 200
        },
        title: {
            text: 'TOP 5 DONORS'
        },
        // subtitle: {
        //     text: 'Source: <a href="https://en.wikipedia.org/wiki/World_population">Wikipedia.org</a>'
        // },
        xAxis: {
            type: "category",
            lineWidth: 0,
            tickWidth: 0,
            shadow:false
           // lineWidth: 0,
           // minorGridLineWidth: 0,
           // lineColor: 'transparent',
           // minorTickLength: 0,
           // tickLength: 0
        },
        yAxis: {
          visible: false
        },
        legend: {
          enabled: false
        },
        // xAxis: {
        //     categories: data.map(function(m) { return m.name;}),
        //     title: {
        //         text: null
        //     }
        // },
        // yAxis: {
        //     min: 0,
        //     title: {
        //         text: 'Population (millions)',
        //         align: 'high'
        //     },
        //     labels: {
        //         overflow: 'justify'
        //     }
        // },
        // tooltip: {
        //     valueSuffix: ' millions'
        // },
        plotOptions: {
            bar: {
                color:"#ffffff",
                dataLabels: {
                    enabled: true,
                    padding: 6,
                    shadow: false
                },
                pointInterval:1,
                pointWidth:15,
                pointPadding: 0,
                groupPadding: 0,
                borderWidth: 0,
                shadow: false
            }
        },
        // legend: {
        //     layout: 'vertical',
        //     align: 'right',
        //     verticalAlign: 'top',
        //     x: -40,
        //     y: 80,
        //     floating: true,
        //     borderWidth: 1,
        //     backgroundColor: ((Highcharts.theme && Highcharts.theme.legendBackgroundColor) || '#FFFFFF'),
        //     shadow: true
        // },
        credits: {
            enabled: false
        },
        series: [{ data: data.map(function(m) { return [m.name, m.value];}) }]
    });
  }

  // dev block
  // filter_extended.find(".filter-toggle").trigger("click");
  // filter_extended.find(".filter-input:nth-of-type(3) .toggle").trigger("click");

});

