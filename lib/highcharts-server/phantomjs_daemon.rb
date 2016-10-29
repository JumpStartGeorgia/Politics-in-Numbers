require 'daemons'
pth = File.dirname(File.expand_path(__FILE__))
Daemons.run "#{pth}/phantomjs.rb" #, dir: 'tmp/pids', dir_mode: :normal
