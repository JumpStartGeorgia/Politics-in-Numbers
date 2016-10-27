require 'daemons'
Daemons.run 'phantomjs.rb', dir: 'tmp/pids', dir_mode: :normal
