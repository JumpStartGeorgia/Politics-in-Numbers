# These tasks are for controlling puma and the puma jungle

namespace :puma do
  desc "Generates a new puma.rb in the 'current' directory"
  task :generate_conf do
    conf = ERB.new(File.read('./config/puma.rb.erb')).result
    queue %(echo "-----> Generating new config/puma.rb")

    queue %(
    PWD="$(pwd)"
    if [ $PWD = #{user_path} ]; then
      echo "-----> Copying new puma.rb to: #{puma_conf}"
      echo '#{conf}' > #{puma_conf};
    else
      echo "-----> Copying new puma.rb to: $PWD/config/puma.rb"
      echo '#{conf}' > ./config/puma.rb;
    fi
    )
  end

  desc 'Start puma'
  task start: :environment do
    queue %(
      if [ -e '#{pumactl_socket}' ]; then
        echo 'Puma is already running!';
      else
        cd #{deploy_to}/#{current_path} && #{puma_cmd} -q -d -e #{puma_env} \
          -C #{puma_conf}
      fi
        )
  end

  desc 'Stop puma'
  task stop: :environment do
    queue %(
      if [ -e '#{pumactl_socket}' ]; then
        cd #{deploy_to}/#{current_path} && #{pumactl_cmd} -S #{puma_state} \
          -F #{puma_conf} stop
        rm -f '#{pumactl_socket}'
      else
        echo 'Puma is not running!';
      fi
        )
  end

  desc 'Restart puma'
  task restart: :environment do
    queue %(
      echo "Running puma restart command"
      if [ -e '#{pumactl_socket}' ]; then
        cd #{deploy_to}/#{current_path} && #{pumactl_cmd} -S #{puma_state} \
          -F #{puma_conf} restart
      else
        echo 'Puma is not running!';
      fi
        )
  end

  desc 'Restart puma (phased restart)'
  task phased_restart: :environment do
    queue %(
      echo "Running puma phased_restart command"
      if [ -e '#{pumactl_socket}' ]; then
        cd #{deploy_to}/#{current_path} && #{pumactl_cmd} -S #{puma_state} \
          -F #{puma_conf} phased-restart
      else
        echo 'Puma is not running!';
      fi
        )
  end

  desc 'View status of puma server'
  task status: :environment do
    queue %(
      if [ -e '#{pumactl_socket}' ]; then
        cd #{deploy_to}/#{current_path} && #{pumactl_cmd} -S #{puma_state} \
          -F #{puma_conf} status
      else
        echo 'Puma is not running!';
      fi
        )
  end

  desc 'View information about puma server'
  task stats: :environment do
    queue %(
      if [ -e '#{pumactl_socket}' ]; then
        cd #{deploy_to}/#{current_path} && #{pumactl_cmd} -S #{puma_state} \
          -F #{puma_conf} stats
      else
        echo 'Puma is not running!';
      fi
        )
  end

  namespace :jungle do
    desc 'Adds the application to the puma jungle'
    task :add do |task|
      system %(echo "")
      system %(echo "Adding application to puma jungle at /etc/puma.conf")
      system %(#{sudo_ssh_cmd(task)} 'sudo /etc/init.d/puma add #{deploy_to} \
                 #{user} #{puma_conf} #{puma_log}')
      system %(echo "")
    end

    desc 'Removes the application from the puma jungle'
    task :remove do |task|
      system %(echo "")
      system %(echo "Removing application from puma jungle at /etc/puma.conf")
      system %(#{sudo_ssh_cmd(task)} \
                 'sudo /etc/init.d/puma remove #{deploy_to}')
      system %(echo "")
    end

    desc 'Starts the puma jungle'
    task :start do |task|
      system %(echo "")
      system %(echo "Starting all puma jungle applications")
      system %(#{sudo_ssh_cmd(task)} 'sudo /etc/init.d/puma start')
      system %(echo "")
    end

    desc 'Stops the puma jungle'
    task :stop do |task|
      system %(echo "")
      system %(echo "Stopping all puma jungle applications")
      system %(#{sudo_ssh_cmd(task)} 'sudo /etc/init.d/puma stop')
      system %(echo "")
    end

    desc 'Checks the status of the puma jungle'
    task :status do |task|
      system %(echo "")
      system %(echo "Checking status of all puma jungle applications")
      system %(#{sudo_ssh_cmd(task)} 'sudo /etc/init.d/puma status')
      system %(echo "")
    end

    desc 'Restarts the puma jungle'
    task :restart do |task|
      system %(echo "")
      system %(echo "Restarting all puma jungle applications")
      system %(#{sudo_ssh_cmd(task)} 'sudo /etc/init.d/puma restart')
      system %(echo "")
    end

    desc 'Lists the apps in the puma jungle (outputs /etc/puma.conf)'
    task :list do |task|
      system %(echo "")
      system %(echo "Listing all apps in puma jungle")
      system %(#{sudo_ssh_cmd(task)} 'sudo cat /etc/puma.conf')
      system %(echo "")
    end
  end
end
