# These tasks can be used to quickly make nginx redirect all traffic to
# a maintenance page.

# Maintenance file locations
set :enabled_maintenance, -> { "#{full_current_path}/public/maintenance.html" }
set :disabled_maintenance, lambda {
  "#{full_current_path}/public/maintenance_disabled.html"
}

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  invoke :'rbenv:load'
end

namespace :maintenance do
  desc 'Redirect all incoming traffic to public/maintenance.html'
  task :enable do
    queue! %(
    if [ -f #{enabled_maintenance} ];
      then
        echo "Maintenance is already enabled."
      else
        mv #{disabled_maintenance} #{enabled_maintenance}
        echo "Maintenance has been enabled."
      fi
    )
  end

  desc 'Stop redirecting traffic to public/maintenance.html'
  task :disable do
    queue! %(
    if [ -f #{disabled_maintenance} ];
      then
        echo "Maintenance is already disabled."
      else
        mv #{enabled_maintenance} #{disabled_maintenance}
        echo "Maintenance has been disabled."
      fi
    )
  end

  desc 'Check if maintenance is enabled'
  task :status do
    queue! %(
    if [ -f #{enabled_maintenance} ];
      then
         echo "Maintenance is enabled."
      else
         echo "Maintenance is disabled."
      fi
    )
  end
end
