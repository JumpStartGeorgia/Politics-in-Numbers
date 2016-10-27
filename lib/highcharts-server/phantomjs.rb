pth = File.dirname(File.expand_path(__FILE__))
exec "phantomjs \"#{pth}/highcharts-convert.js\" -host 127.0.0.1 -port 3003"
