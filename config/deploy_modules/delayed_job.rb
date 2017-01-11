namespace :delayed_job do
  desc 'Stop delayed_job'
  task stop: :environment do
    queue %(echo "-----> Stop delayed_job")
    queue! %(cd #{full_current_path} && RAILS_ENV=#{rails_env} #{delayed_job} #{delayed_job_additional_params} stop --pid-dir='#{shared_path}/#{delayed_job_pid_dir}')
  end

  desc 'Start delayed_job'
  task start: :environment do
    queue %(echo "-----> Start delayed_job")
    queue %(echo "-----> Start delayed_job#{full_current_path}--#{rails_env}--#{delayed_job}--#{delayed_job_additional_params}--#{delayed_job_processes}--#{shared_path}--#{delayed_job_pid_dir}")
    queue! %(cd #{full_current_path} && RAILS_ENV=#{rails_env} #{delayed_job} #{delayed_job_additional_params} start -n #{delayed_job_processes} --pid-dir='#{shared_path}/#{delayed_job_pid_dir}')
  end

  desc 'Restart delayed_job'
  task restart: :environment do
    queue %(echo "-----> Restart delayed_job")
    queue! %(cd #{full_current_path} && RAILS_ENV=#{rails_env} #{delayed_job} #{delayed_job_additional_params} restart -n #{delayed_job_processes} --pid-dir='#{shared_path}/#{delayed_job_pid_dir}')
  end

  desc 'delayed_job status'
  task status: :environment do
    queue %(echo "-----> Delayed job status")
    queue! %(cd #{full_current_path} && RAILS_ENV=#{rails_env} #{delayed_job} #{delayed_job_additional_params} status --pid-dir='#{shared_path}/#{delayed_job_pid_dir}')
  end

  desc 'delayed_job setup'
  task setup: :environment do
    queue %(echo "-----> Delayed job Setup (generate bin/delayed_job script)")
    queue! %(cd #{full_current_path} && RAILS_ENV=#{rails_env} bundle exec rails generate delayed_job)
  end
end
