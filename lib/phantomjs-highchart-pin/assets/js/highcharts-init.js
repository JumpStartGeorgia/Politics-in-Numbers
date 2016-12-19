(function(H) { // for highchart to recognize maxPointWidth property
    var each = H.each;
    H.wrap(H.seriesTypes.column.prototype, "drawPoints", function (proceed) {
        var series = this;
        if(series.data.length > 0 ){
            var width = series.barW > series.options.maxPointWidth ? series.options.maxPointWidth : series.barW;
            each(this.data, function (point) {
                point.shapeArgs.x += (point.shapeArgs.width - width) / 2;
                point.shapeArgs.width = width;
            });
        }
        proceed.call(this);
    })
})(Highcharts);

function escapeRegExp(string){ return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); } // $& means the whole matched string
// some custom helpers
(function (){
  if(!String.prototype.trimr)
  {
    String.prototype.trimr = function(c) {
      c = escapeRegExp(c);
      var r = (!c) ? new RegExp('\\s+$') : new RegExp(c+'+$');
      return this.replace(r, '');
    };
  }
})();
