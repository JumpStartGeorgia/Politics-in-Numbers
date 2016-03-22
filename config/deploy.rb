# load .env variables
require 'dotenv'
Dotenv.load

# allows debugging with 'binding.pry'
require 'pry-byebug'

require 'erb'
require 'mina/multistage'
require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'
require_relative 'deploy_modules/maintenance'
require_relative 'deploy_modules/puma'
require_relative 'deploy_modules/nginx'

set :user_path, -> { "/home/#{user}" }
set :deploy_to, -> { "#{user_path}/#{application}" }
set :full_current_path, -> { "#{deploy_to}/#{current_path}" }
set :full_shared_path, -> { "#{deploy_to}/#{shared_path}" }
set :full_tmp_path, -> { "#{deploy_to}/tmp" }
set_default :branch, 'master'

set :initial_directories, lambda {
  [
    "#{full_shared_path}/log",
    "#{full_shared_path}/config",
    "#{full_shared_path}/public/system",
    "#{full_tmp_path}/puma/sockets",
    "#{full_tmp_path}/assets"
  ]
}

set :shared_paths, %w(.env log public/system)
set :forward_agent, true
set :rails_env, -> { "#{stage}" }
set :robots_path, -> { "#{full_current_path}/public/robots.txt" }
set_default :visible_to_robots, true

# SSH Port: the variable ssh_port is used in this config, to distinguish it
# from puma_port. The variable 'port' is also set here because mina uses it
# for deploying.
set_default :ssh_port, 22
set :port, -> { ssh_port } # Mina uses the variable port

# Puma settings
set :web_server, :puma
set :puma_role, -> { user }
set :puma_socket, -> { "#{deploy_to}/tmp/puma/sockets/puma.sock" }
set :puma_pid, -> { "#{deploy_to}/tmp/puma/pid" }
set :puma_state, -> { "#{deploy_to}/tmp/puma/state" }
set :pumactl_socket, -> { "#{deploy_to}/tmp/puma/sockets/pumactl.sock" }
set :puma_conf, -> { "#{full_current_path}/config/puma.rb" }
set :puma_cmd,       -> { "#{bundle_prefix} puma" }
set :pumactl_cmd,    -> { "#{bundle_prefix} pumactl" }
set :puma_error_log, -> { "#{full_shared_path}/log/puma.error.log" }
set :puma_access_log, -> { "#{full_shared_path}/log/puma.access.log" }
set :puma_log, -> { "#{full_shared_path}/log/puma.log" }
set :puma_env, -> { "#{rails_env}" }
set :puma_port, '9292'
set_default :puma_worker_count, '1'
set_default :puma_thread_count_min, '1'
set_default :puma_thread_count_max, '1'

# Nginx settings
set :nginx_conf, -> { "#{full_current_path}/config/nginx.conf" }
set :nginx_symlink, -> { "/etc/nginx/sites-enabled/#{application}" }

# SSL settings
set_default :use_ssl, false
set :ssl_key, -> { "/etc/sslmate/#{web_url}.key" }
set :ssl_cert, -> { "/etc/sslmate/#{web_url}.chained.crt" }

# Assets settings
set :precompiled_assets_dir, 'public/assets'

# Rails settings
set :temp_env_example_path, -> { "#{user_path}/.env.example-#{application}" }
set :shared_env_path, -> { "#{full_shared_path}/.env" }

# Fetch Head location: this file contains the currently deployed git commit hash
set :fetch_head, -> { "#{deploy_to}/scm/FETCH_HEAD" }

namespace :rails do
  desc "Opens the deployed application's .env file in vim for editing"
  task :edit_env do
    queue! %(vim #{shared_env_path})
  end

  desc 'Creates new robots.txt on server from robots.txt.erb template'
  task :generate_robots do
    robots = ERB.new(File.read('./config/robots.txt.erb')).result
    queue %(echo "-----> Generating new public/robots.txt")

    queue %(
    PWD="$(pwd)"
    if [ $PWD = #{user_path} ]; then
      echo "-----> Copying new robots.txt to: #{robots_path}"
      echo '#{robots}' > #{robots_path};
    else
      echo "-----> Copying new robots.txt to: $PWD/public/robots.txt"
      echo '#{robots}' > ./public/robots.txt;
    fi
    )
  end

  namespace :log do
    desc 'Tail a log file; set `lines` to number of lines and `log` to log'\
         "file name; example: 'mina rails:log lines=100 log=production.log'"
    task :tail do
      ENV['n'] ||= '10'
      ENV['f'] ||= "#{stage}.log"

      puts "Tailing file #{ENV['f']}; showing last #{ENV['n']} lines"
      queue! %(tail -n #{ENV['n']} -f #{full_current_path}/log/#{ENV['f']})
    end

    desc 'List all log files'
    task :list do
      queue! %(ls -la #{full_current_path}/log/)
    end
  end
end

namespace :git do
  desc 'Git diff local with server'
  task :diff_local do
    diff = `git diff #{deployed_commit}..#{local_commit_hash}`
    puts diff
  end

  desc 'Remove FETCH_HEAD file containing currently deployed git commit hash; '\
       'this will force user to precompile on next deploy'
  task :remove_fetch_head do
    queue %(
      echo '-----> Removing #{fetch_head}'
      rm #{fetch_head}
        )
  end
end

namespace :deploy do
  desc 'Ensures that local git repository is clean and in '\
       'sync with the origin repository used for deploy.'
  task :check_revision do
    unless `git rev-parse HEAD` == `git rev-parse origin/#{branch}`
      system %(echo "WARNING: HEAD is not the same as origin/#{branch}")
      system %(echo "Run 'git push' to sync changes.")
      exit
    end

    unless `git status`.include? 'nothing to commit, working directory clean'
      system %(echo "WARNING: There are uncommitted changes to the local git")
      system %(echo "repository, which may cause problems for locally")
      system %(echo "precompiling assets.")
      system %(echo "Please clean local repository with")
      system %("'git stash' or 'git reset'.")
      exit
    end
  end

  desc 'Rollback to previous deploy'
  task :rollback do
    # First runs original deploy:rollback task, then runs below code
    invoke :'puma:restart'
    invoke :'deploy:assets:copy_current_to_tmp'
    invoke :'git:remove_fetch_head'
  end

  namespace :assets do
    desc 'Decides whether to precompile assets'
    task :decide_whether_to_precompile do
      set :precompile_assets, false
      if ENV['precompile'] == 'true'
        set :precompile_assets, true
      else
        # Locations where assets may have changed; check Gemfile.lock to
        # ensure that gem assets are the same
        asset_files_directories = 'app/assets vendor/assets Gemfile.lock'

        current_commit = local_commit_hash

        # If FETCH_HEAD file does not exist or deployed_commit doesn't look
        # like a hash, ask user to force precompile
        if deployed_commit.nil? || deployed_commit.length != 40
          system %(echo "WARNING: Cannot determine the commit hash of the")
          system %(echo "previous release on the server.")
          system %(echo "If this is your first deploy, deploy like this:")
          system %(echo "")
          system %(echo "mina #{stage} deploy first_deploy=true --verbose")
          system %(echo "")
          system %(echo "If not, you can force precompile like this:")
          system %(echo "")
          system %(echo "mina #{stage} deploy precompile=true --verbose")
          system %(echo "")
          exit
        else
          git_diff = diff_for_files_btw_commits(
            deployed_commit,
            current_commit,
            asset_files_directories
          )

          # If git diff length is not 0, then either 1) the assets have
          # changed or 2) git cannot recognize the deployed commit and
          # issues an error. In both these situations, precompile assets.
          if git_diff.nil? || git_diff.length != 0
            set :precompile_assets, true
          else
            system %(echo "-----> Assets unchanged; skipping precompile assets")
          end
        end
      end
    end

    desc 'Precompile assets locally and rsync to tmp/assets folder on server.'
    task :local_precompile do
      system %(echo "-----> Cleaning assets locally")
      system %(RAILS_ENV=#{rails_env} bundle exec \
                 rake assets:clean RAILS_GROUPS=assets)

      system %(echo "-----> Precompiling assets locally")
      system %(RAILS_ENV=#{rails_env} bundle exec \
                 rake assets:precompile RAILS_GROUPS=assets)

      system %[echo "-----> RSyncing remote assets (tmp/assets) \
                     with local assets (#{precompiled_assets_dir})"]

      system %(rsync #{rsync_verbose} -e 'ssh -p #{ssh_port}' \
                 --recursive --times --delete ./#{precompiled_assets_dir}/. \
                 #{user}@#{domain}:#{deploy_to}/tmp/assets)
    end

    task :copy_tmp_to_current do
      queue %(echo "-----> Copying assets from \
                    tmp/assets to current/#{precompiled_assets_dir}")
      queue! %(cp -a #{deploy_to}/tmp/assets/. ./#{precompiled_assets_dir})
    end

    task :copy_current_to_tmp do
      queue %(echo "-----> Replacing tmp/assets with")
      queue %(echo " current/#{precompiled_assets_dir}")
      queue! %(rm -r #{deploy_to}/tmp/assets)
      queue! %(cp -a #{full_current_path}/#{precompiled_assets_dir}/. \
                 #{deploy_to}/tmp/assets)
    end
  end
end

desc 'Setup directories and .env file; should be run before first deploy.'
task setup: :environment do
  if capture(%(ls #{full_shared_path}/.env))
     .split(' ')[0] == "#{shared_env_path}"
    env_exists = true
  else
    env_exists = false
  end

  unless env_exists
    system %(scp -P #{ssh_port} .env.example \
               #{user}@#{domain}:#{temp_env_example_path})
  end

  initial_directories.each do |dir|
    queue! %(mkdir -p "#{dir}")
    queue! %(chmod g+rx,u+rwx "#{dir}")
  end

  unless env_exists
    queue %(echo "Moving copy of local .env.example to #{shared_env_path}")
    queue! %(mv #{temp_env_example_path} #{shared_env_path})
    queue %(echo "")
    queue %(echo "----------------------- IMPORTANT -----------------------")
    queue %(echo "")
    queue %(echo "Run the following command and add your secrets to .env:")
    queue %(echo "")
    queue %(echo "mina #{stage} rails:edit_env")
    queue %(echo "")
    queue %(echo "Then deploy for the first time like this:")
    queue %(echo "")
    queue %(echo "mina #{stage} deploy first_deploy=true --verbose")
    queue %(echo "")
    queue %(echo "----------------------- IMPORTANT -----------------------")
    queue %(echo "")
  end
end

desc 'Deploys the current version to the server; options: '\
     '"first_deploy=true", "branch=deploy_from_this_branch", "precompile=true"'
task deploy: :environment do
  deploy do
    set :branch, ENV['branch'] unless ENV['branch'].nil?

    if ENV['first_deploy'] == 'true'
      first_deploy = true
      ENV['precompile'] = 'true'
    end

    set :rsync_verbose, '--verbose'
    unless verbose_mode?
      set :rsync_verbose, ''
      set :bundle_options, "#{bundle_options} --quiet"
    end

    invoke :'deploy:check_revision'
    invoke :'deploy:assets:decide_whether_to_precompile'
    invoke :'deploy:assets:local_precompile' if precompile_assets
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'deploy:assets:copy_tmp_to_current'
    invoke :'nginx:generate_conf'
    invoke :'puma:generate_conf'
    invoke :'rails:generate_robots'
    invoke :'deploy:cleanup'

    to :launch do
      queue! "mkdir -p #{full_current_path}/tmp/"
      queue! "touch #{full_current_path}/tmp/restart.txt"
      if first_deploy
        invoke :'puma:start'
        queue %(echo "")
        queue %(echo "--------------------- IMPORTANT ---------------------")
        queue %(echo "")
        queue %(echo "This is the first deploy, so you need to finish setup:")
        queue %[echo "(Insert a user with sudo access into <username>)"]
        queue %(echo "")
        queue %(echo "mina #{stage} post_setup sudo_user=<username>")
        queue %(echo "")
        queue %(echo "--------------------- IMPORTANT ---------------------")
        queue %(echo "")
      else
        diff = diff_for_files_btw_commits(
          deployed_commit,
          local_commit_hash,
          'db/schema.rb Gemfile.lock'
        )

        if diff.nil?
          schema_or_gems_unchanged = false
        else
          schema_or_gems_unchanged = diff.length == 0
        end

        # If neither db schema nor Gemfile.lock have changed, it's safe
        # to perform phased_restart. Otherwise, do a hot restart. See
        # following link for difference between the two restarts:
        # https://github.com/puma/puma#normal-vs-hot-vs-phased-restart
        if schema_or_gems_unchanged
          invoke :'puma:phased_restart'
        else
          invoke :'puma:restart'
        end
        invoke :finished_deploy_message
      end
    end
  end
end

desc 'Creates Nginx symlink, adds app to puma jungle, and starts '\
     'and stops Nginx; should be run after first deploy.'
task :post_setup do
  invoke :'nginx:create_symlink'
  invoke :'puma:jungle:add'
  invoke :'nginx:stop'
  invoke :'nginx:start'
  invoke :finished_deploy_message
end

task :finished_deploy_message do
  queue %(echo "")
  queue %(echo "-------------------- Finished Deploy --------------------")
  queue %(echo "")
  queue %(echo "Your site should be deployed and running at:")
  queue %(echo "")
  queue %(echo "#{web_url}")
  queue %(echo "")
end

desc 'Removes application directory from server, removes nginx symlink, '\
     'removes app from puma jungle and restarts nginx.'
task :destroy do
  invoke :remove_application
  invoke :'nginx:remove_symlink'
  invoke :'puma:jungle:remove'
  invoke :'nginx:stop'
  invoke :'nginx:start'
end

desc 'Removes application directory from server.'
task :remove_application do |task|
  system %(echo "")
  system %(echo "Removing application at #{deploy_to}")
  system %(echo "WARNING: DO NOT ENTER sudo password if you're unsure.")
  system %(#{sudo_ssh_cmd(task)} 'sudo rm -rf #{deploy_to}')
  system %(echo "")
end

private

def sudo_ssh_cmd(task)
  "ssh #{get_sudo_user(task)}@#{domain} -t -p #{ssh_port}"
end

def get_sudo_user(task)
  sudo_user = ENV['sudo_user']

  no_sudo_user_error(task) unless sudo_user

  sudo_user
end

def no_sudo_user_error(task)
  system %(echo "")
  system %(echo "In order to run this command, please include a 'sudo_user' ")
  system %(echo "option set to a user that has sudo permissons ")
  system %(echo "on the server:")
  system %(echo "")
  system %(echo "mina #{stage} #{task} sudo_user=<username>")
  system %(echo "")
  exit
end

def local_commit_hash
  `git rev-parse HEAD`.strip
end

def deployed_commit
  return deployed_commit_hash unless deployed_commit_hash.nil?

  # Determine deployed commit hash if it hasn't been set yet
  deployed_commit_hash = capture(%(cat #{fetch_head})).split(' ')[0]
  if deployed_commit_hash.nil?
    # If hash is nil, set it to empty string so that this code isn't run again
    set :deployed_commit_hash, ''
  else
    set :deployed_commit_hash, deployed_commit_hash
  end
end

def diff_for_files_btw_commits(commit1, commit2, files_dirs)
  return nil if commit1.nil? || commit1 == ''
  return nil if commit2.nil? || commit2 == ''
  `git diff --name-only #{commit1}..#{commit2} #{files_dirs}`
end
