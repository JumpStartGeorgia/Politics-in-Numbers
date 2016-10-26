/* global $ gon Highcharts*/
//= require jquery
//= require jquery_ujs
//= require jquery-ui/tooltip
//= require highcharts

$(document).ready(function (){
  var chart = $("#chart");

  function bar_chart (resource, bg) {
    chart.highcharts({
      chart: {
        type: "bar",
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
        text: resource.title,
        style: {
          color: "#5d675b",
          fontSize:"18px",
          fontFamily: "firasans_r",
          textShadow: "none"
        }
      },
      subtitle: {
        text: resource.subtitle,
        style: {
          color: "#5d675b",
          fontSize:"12px",
          fontFamily: "firasans_book",
          textShadow: "none"
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
            textShadow: "none"
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
              textShadow: "none"
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
          textShadow: "none",
          fontWeight:"normal"
        },
        formatter: function () {
          return "<b>" + this.key + "</b>: " + Highcharts.numberFormat(this.y);
        }
      }
    });
  }

  function grouped_advanced_column_chart (resource, bg) {
    chart.highcharts({
      chart: {
        type: "column",
        backgroundColor: bg
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
            textShadow: "none"
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
            textShadow: "none"
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
            textShadow: "none"
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
          textShadow: "none",
          fontWeight:"normal"
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
          textShadow: "none",
          fontWeight:"normal"
        }
      }
    });
  }

  function build_chart () {
    chart.addClass("loader");
    var data = gon.data;
    if(data) {
      if(gon.is_donation) {
        if(gon.tp === "a" || gon.tp === "b") {
          bar_chart(data["c" + gon.tp], (gon.tp === "a" ? "#EBE187" : "#B8E8AD"));
        }
      }
      else {
        if(gon.tp === "a") {
          grouped_advanced_column_chart(data.ca, "#fff");
        }
      }
    }
    chart.removeClass("loader");
  }

  function bind () {
    $(document).tooltip({
      content: function () { return $(this).attr("data-retitle"); },
      items: "text[data-retitle]",
      track: true
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
      }
    });
    (function(H) { // for highchart to recognize maxPointWidth property
        var each = H.each;
        H.wrap(H.seriesTypes.column.prototype, "drawPoints", function(proceed) {
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

  (function init () {
    init_highchart();
    bind();
    build_chart();
  })();
});

