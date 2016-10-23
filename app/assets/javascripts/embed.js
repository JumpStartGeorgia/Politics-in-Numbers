//= require jquery
//= require jquery_ujs
//= require dataTables/jquery.dataTables
//= require dataTables/extras/dataTables.responsive
//= require dataTables.pagination.js
//= require jquery-ui/tooltip
//= require highcharts


/* global $ gon */

$(document).ready(function (){
  // console.log("explore ready");
  var js = {
      cache: {}
    },
    w = 0,
    h = 0,
    chart = $("#chart"),
    explore = $("#explore"),
    explore_button = $("#explore_button"),
    finance_toggle = $("#finance_toggle"),
    donation_toggle = $("#donation_toggle"),
    filter_type = $("#filter_type"),
    is_type_donation = true,
    filter_extended = $("#filter_extended"),
    finance_category = $("#finance_category"),
    view_content = $(".view-content"),
    view_not_found = $(".not-found"),
    loader = $(".view-loader"),
    donation_total_amount = $("#donation_total_amount span"),
    donation_total_donations = $("#donation_total_donations span"),
    donation_table = $("#donation_table table"),
    finance_table = $("#finance_table table"),
    finance_datatable;




  function resize() {
    w = $(window).width();
    h = $(window).height();
  }
  function bind() {

    $(window).on("resize", function(){
      resize();
    });
    resize();



    $(document).tooltip({
      content: function() { return $(this).attr("data-retitle"); },
      items: "text[data-retitle]",
      track: true
    });
  }

  // function filter() {
  //   loader.fadeIn();
  //   //console.log("start filter", is_type_donation);
  //   var tmp, cacher_id, _id, _id, finance_id, obj;

  //   if(gon.gonned) {
  //     [donation, finance].forEach( function (obj) {
  //       obj.set_by_url();
  //       tmp = obj.get();
  //       _id = obj.id(tmp);
  //       js.cache[_id] = gon[obj.name + "_data"];
  //       filter_callback(js.cache[_id], obj.name);
  //     });
  //     gon.gonned = false;
  //   } else {
  //     obj = is_type_donation ? donation : finance;
  //     tmp = obj.get();
  //     _id = obj.id(tmp);
  //     obj.url(tmp);

  //     if(!js.cache.hasOwnProperty(_id)) {
  //       var filters = {};
  //       filters[obj.name] = tmp;
  //       $.ajax({
  //         url: "explore_filter",
  //         dataType: 'json',
  //         data: filters,
  //         success: function(data) {
  //           js.cache[_id] = data[obj.name];
  //           if(data.hasOwnProperty("donation")) { filter_callback(data.donation, "donation"); }
  //           if(data.hasOwnProperty("finance")) { filter_callback(data.finance, "finance"); }
  //         }
  //       });
  //     }
  //     else {
  //       filter_callback(js.cache[_id], obj.name);
  //     }
  //   }
  // }
  function build_chart () {
    chart.addClass("loader");
    // console.log("filter_callback", data);
    //view_not_found.addClass("hidden");
    var data = gon.data;
    console.log(data, gon.tp);
    if(data) {
      if(gon.is_donation) {
        if(gon.tp === "ca" || gon.tp === "cb") {
          bar_chart(data[gon.tp], data[gon.tp + "ca_title"], data.chart_subtitle, (gon.tp === "ca" ? "#EBE187" : "#B8E8AD"));
        }
      }
      else {
        if(gon.tp === "ca") {
          grouped_advanced_column_chart(data.ca, "#fff");
          //grouped_column_chart("#finance_chart", data.ca, "#fff");
        }
      }
    }
    else {
      //view_not_found.removeClass("hidden");
    }
    chart.removeClass("loader");
  }
  function bar_chart (series_data, title, subtitle, bg) {
    //console.log("chart", elem, series_data);
    chart.highcharts({
      chart: {
          type: 'bar',
          backgroundColor: bg,
          // height: "100%",
          // width: w > 992 ? (view_content.width()-386)/2 : w - 12,
          events: {
            load: function () {
              var tls = $(".highcharts-xaxis-labels text title"),
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
  function grouped_column_chart (resource, bg) {
    console.log("chart", elem, resource);
    chart.highcharts({
      chart: {
          type: 'column',
          backgroundColor: bg,
          // height: 400,
          // width: w > 992 ? (view_content.width()-28)/2 : w - 12,
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
  function grouped_advanced_column_chart (resource, bg) {
    console.log(resource, "advanced");
    chart.highcharts({
      chart: {
          type: 'column',
          backgroundColor: bg,
          // height: 400,
          // width: w > 992 ? (view_content.width()-28)/2 : w - 12
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
        enabled: false
        // ,
        // href: gon.url,
        // text: gon.app_name
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

  (function init() {
    init_highchart();
    bind();
    is_type_donation = gon.is_donation;
    build_chart();
  })();
});

