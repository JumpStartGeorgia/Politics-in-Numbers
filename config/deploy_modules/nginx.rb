namespace :nginx do
  desc "Generates a new Nginx configuration in the app's current folder."
  task :generate_conf do
    conf = if use_ssl
             queue %(echo "-----> Generating SSL Nginx Config file")
             ERB.new(File.read('./config/nginx_ssl.conf.erb')).result
           else
             queue %(echo "-----> Generating Non-SSL Nginx Config file")
             ERB.new(File.read('./config/nginx.conf.erb')).result
           end

    queue %(
    PWD="$(pwd)"
    if [ $PWD = #{user_path} ]; then
      echo "-----> Copying new nginx.conf to: #{nginx_conf}"
      echo '#{conf}' > #{nginx_conf};
    else
      echo "-----> Copying new nginx.conf to: $PWD/config/nginx.conf"
      echo '#{conf}' > ./config/nginx.conf;
    fi
    )
  end

  desc 'Tests all Nginx configuration files for validity.'
  task :test do |task|
    system %(echo "")
    system %(echo "Testing Nginx configuration files for validity")
    system %(#{sudo_ssh_cmd(task)} 'sudo nginx -t')
    system %(echo "")
  end

  desc 'Creates symlink to nginx.conf from the Nginx sites-enabled directory.'
  task :create_symlink do |task|
    system %(echo "")
    system %(echo "Creating Nginx symlink: #{nginx_symlink} ===> #{nginx_conf}")
    system %(#{sudo_ssh_cmd(task)} 'sudo ln -nfs #{nginx_conf} \
      #{nginx_symlink}')
    system %(echo "")
  end

  desc 'Removes symlink to nginx.conf from the Nginx sites-enabled directory.'
  task :remove_symlink do |task|
    system %(echo "")
    system %(echo "Removing Nginx symlink: #{nginx_symlink}")
    system %(#{sudo_ssh_cmd(task)} 'sudo rm #{nginx_symlink}')
    system %(echo "")
  end

  desc 'Starts the Nginx server.'
  task :start do |task|
    system %(echo "")
    system %(echo "Starting Nginx.")
    system %(#{sudo_ssh_cmd(task)} 'sudo service nginx start')
    system %(echo "")
  end

  desc 'Stops the Nginx server.'
  task :stop do |task|
    system %(echo "")
    system %(echo "Stopping Nginx.")
    system %(#{sudo_ssh_cmd(task)} 'sudo service nginx stop')
    system %(echo "")
  end

  desc 'Reloads the Nginx server.'
  task :reload do |task|
    system %(echo "")
    system %(echo "Restarts Nginx.")
    system %(#{sudo_ssh_cmd(task)} 'sudo nginx -s reload')
    system %(echo "")
  end

  desc 'Checks the status of the Nginx server. Requires sudo_user option.'
  task :status do |task|
    system %(echo "")
    system %(echo "Checking Nginx status.")
    system %(#{sudo_ssh_cmd(task)} 'sudo service nginx status')
    system %(echo "")
  end
end
