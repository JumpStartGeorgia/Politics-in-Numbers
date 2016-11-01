namespace :phantomjs_highcharts do
  desc 'Starts the Phantomjs Highcharts server.'
  task :start do |task|
    system %(echo "")
    system %(echo "Starting Phantomjs Highcharts.")
    system %(#{sudo_ssh_cmd(task)} 'sudo service phantomjs-highchart-pin start')
    system %(echo "")
  end

  desc 'Stops the Phantomjs Highcharts server.'
  task :stop do |task|
    system %(echo "")
    system %(echo "Stopping Phantomjs Highcharts.")
    system %(#{sudo_ssh_cmd(task)} 'sudo service phantomjs-highchart-pin stop')
    system %(echo "")
  end

  desc 'Restarts the Phantomjs Highcharts server.'
  task :restart do |task|
    system %(echo "")
    system %(echo "Restarts Phantomjs Highcharts.")
    system %(#{sudo_ssh_cmd(task)} 'sudo service phantomjs-highchart-pin restart')
    system %(echo "")
  end

  desc 'Force reload the Phantomjs Highcharts server.'
  task :restart do |task|
    system %(echo "")
    system %(echo "Force reload Phantomjs Highcharts.")
    system %(#{sudo_ssh_cmd(task)} 'sudo service phantomjs-highchart-pin force-reload')
    system %(echo "")
  end

  desc 'Checks the status of the Phantomjs Highcharts server.'
  task :status do |task|
    system %(echo "")
    system %(echo "Checking Phantomjs Highcharts status.")
    system %(#{sudo_ssh_cmd(task)} 'sudo service phantomjs-highchart-pin status')
    system %(echo "")
  end
end
